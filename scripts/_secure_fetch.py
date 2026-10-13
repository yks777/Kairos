import json
import os
import pwd
import secrets
import stat
import time
import urllib.error
import urllib.parse
import urllib.request

MAX_RESPONSE_BYTES = 1024 * 1024
MAX_CACHE_BYTES = 1024 * 1024


class SafeFetchError(Exception):
    pass


def _directory_flags():
    return os.O_RDONLY | getattr(os, "O_DIRECTORY", 0) | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0)


def _check_directory(fd, expected_uid=None, private=False):
    info = os.fstat(fd)
    if not stat.S_ISDIR(info.st_mode):
        raise SafeFetchError("cache path contains a non-directory")
    if expected_uid is not None and info.st_uid != expected_uid:
        raise SafeFetchError("cache directory is not owned by the current user")
    if private and (info.st_mode & 0o022):
        raise SafeFetchError("cache directory is writable by another user")
    if not private and (info.st_mode & 0o022) and not (info.st_uid == 0 and info.st_mode & stat.S_ISVTX):
        raise SafeFetchError("cache path crosses a writable directory")
    return info


def open_cache_directory():
    uid = os.geteuid()
    try:
        home = pwd.getpwuid(uid).pw_dir
    except Exception as exc:
        raise SafeFetchError("cannot resolve the current user's home directory") from exc
    if not home or not os.path.isabs(home) or home == "/":
        raise SafeFetchError("the current user's home path is invalid")

    parts = [part for part in home.split("/") if part]
    fd = os.open("/", _directory_flags())
    _check_directory(fd)
    try:
        for index, part in enumerate(parts):
            try:
                child = os.open(part, _directory_flags(), dir_fd=fd)
            except OSError as exc:
                raise SafeFetchError("cannot safely open the home directory chain") from exc
            os.close(fd)
            fd = child
            _check_directory(fd, uid if index == len(parts) - 1 else None, index == len(parts) - 1)

        for part in (".cache", "omarchy", "kairos", "markets"):
            try:
                child = os.open(part, _directory_flags(), dir_fd=fd)
            except FileNotFoundError:
                try:
                    os.mkdir(part, 0o700, dir_fd=fd)
                except FileExistsError:
                    pass
                child = os.open(part, _directory_flags(), dir_fd=fd)
            except OSError as exc:
                raise SafeFetchError("cannot safely open the market cache directory") from exc
            os.close(fd)
            fd = child
            _check_directory(fd, uid, True)
        return fd
    except Exception:
        try:
            os.close(fd)
        except OSError:
            pass
        raise


def read_cache(filename):
    directory_fd = open_cache_directory()
    file_fd = None
    reopened_fd = None
    try:
        try:
            file_fd = os.open(filename, os.O_RDONLY | getattr(os, "O_CLOEXEC", 0)
                              | getattr(os, "O_NOFOLLOW", 0), dir_fd=directory_fd)
        except FileNotFoundError:
            return None
        info = os.fstat(file_fd)
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.geteuid() or info.st_nlink != 1:
            raise SafeFetchError("market cache file failed ownership checks")
        if info.st_mode & 0o022 or info.st_size < 2 or info.st_size > MAX_CACHE_BYTES:
            raise SafeFetchError("market cache file failed mode or size checks")
        reopened_fd = os.open("/proc/self/fd/" + str(file_fd), os.O_RDONLY | getattr(os, "O_CLOEXEC", 0))
        reopened_info = os.fstat(reopened_fd)
        if reopened_info.st_dev != info.st_dev or reopened_info.st_ino != info.st_ino:
            raise SafeFetchError("market cache descriptor changed during read")
        chunks = []
        total = 0
        while total <= MAX_CACHE_BYTES:
            block = os.read(reopened_fd, min(65536, MAX_CACHE_BYTES + 1 - total))
            if not block:
                break
            chunks.append(block)
            total += len(block)
        if total > MAX_CACHE_BYTES:
            raise SafeFetchError("market cache exceeds the maximum size")
        raw = b"".join(chunks).decode("utf-8")
        value = json.loads(raw)
        return value if isinstance(value, dict) else None
    except (OSError, UnicodeError, ValueError, SafeFetchError):
        return None
    finally:
        if reopened_fd is not None:
            os.close(reopened_fd)
        if file_fd is not None:
            os.close(file_fd)
        os.close(directory_fd)


def write_cache(filename, value):
    directory_fd = open_cache_directory()
    temp_name = "." + filename + "." + str(os.getpid()) + "." + secrets.token_hex(8) + ".tmp"
    temp_fd = None
    writer_fd = None
    try:
        temp_path = "/proc/self/fd/" + str(directory_fd) + "/" + temp_name
        temp_fd = os.open(temp_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL
                          | getattr(os, "O_CLOEXEC", 0) | getattr(os, "O_NOFOLLOW", 0), 0o600)
        temp_info = os.fstat(temp_fd)
        if not stat.S_ISREG(temp_info.st_mode) or temp_info.st_uid != os.geteuid() or temp_info.st_nlink != 1:
            raise SafeFetchError("temporary cache file failed ownership checks")
        writer_fd = os.open("/proc/self/fd/" + str(temp_fd), os.O_WRONLY | getattr(os, "O_CLOEXEC", 0))
        writer_info = os.fstat(writer_fd)
        if writer_info.st_dev != temp_info.st_dev or writer_info.st_ino != temp_info.st_ino:
            raise SafeFetchError("temporary cache descriptor changed during write")
        raw = json.dumps(value, ensure_ascii=True, separators=(",", ":")).encode("utf-8") + b"\n"
        if len(raw) > MAX_CACHE_BYTES:
            raise SafeFetchError("cache payload exceeds the maximum size")
        view = memoryview(raw)
        while view:
            written = os.write(writer_fd, view)
            view = view[written:]
        os.fsync(writer_fd)
        os.close(writer_fd)
        writer_fd = None
        os.close(temp_fd)
        temp_fd = None
        os.rename(temp_name, filename, src_dir_fd=directory_fd, dst_dir_fd=directory_fd)
        os.fsync(directory_fd)
    finally:
        if writer_fd is not None:
            os.close(writer_fd)
        if temp_fd is not None:
            os.close(temp_fd)
        try:
            os.unlink(temp_name, dir_fd=directory_fd)
        except OSError:
            pass
        os.close(directory_fd)


def _https_only_redirect(allowed_host):
    class RedirectHandler(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, request, file_pointer, code, message, headers, new_url):
            parsed = urllib.parse.urlsplit(new_url)
            if parsed.scheme != "https" or parsed.hostname != allowed_host:
                raise urllib.error.URLError("redirect target was not approved")
            return super().redirect_request(request, file_pointer, code, message, headers, new_url)
    return RedirectHandler()


def fetch_json(url, expected_host, timeout=8):
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != "https" or parsed.hostname != expected_host or parsed.username or parsed.password:
        raise SafeFetchError("market API URL failed validation")
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": "Kairos/1.0 (free personal market data)"
        },
        method="GET"
    )
    opener = urllib.request.build_opener(_https_only_redirect(expected_host))
    with opener.open(request, timeout=timeout) as response:
        final = urllib.parse.urlsplit(response.geturl())
        if final.scheme != "https" or final.hostname != expected_host:
            raise SafeFetchError("market API response origin failed validation")
        length = response.headers.get("Content-Length")
        if length and int(length) > MAX_RESPONSE_BYTES:
            raise SafeFetchError("market API response exceeded the size limit")
        raw = response.read(MAX_RESPONSE_BYTES + 1)
        if len(raw) > MAX_RESPONSE_BYTES:
            raise SafeFetchError("market API response exceeded the size limit")
    value = json.loads(raw.decode("utf-8"))
    if not isinstance(value, (dict, list)):
        raise SafeFetchError("market API returned an invalid JSON structure")
    return value


def now_ms():
    return int(time.time() * 1000)


def emit(value):
    print(json.dumps(value, ensure_ascii=True, separators=(",", ":")))
