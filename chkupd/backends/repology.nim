# chkupd v3 repology backend
import json, strutils, os
import ../../kpkg/modules/runparser
import ../autoupdater
import ../../common/version
import httpclient

proc repologyCheck*(package: string, repo: string, autoUpdate = false,
                skipIfDownloadFails = true) =
        ## Check against Repology database.
        let pkgName = lastPathPart(package)
        var client = newHttpClient(userAgent="Klinux chkupd/"&ver&" (issuetracker: https://github.com/kreatolinux/src/issues)")
        var request = parseJson(client.getContent(
                        "https://repology.org/api/v1/project/"&pkgName))
        var counter = 0
        var version: string
        let packageDir = repo&"/"&pkgName
        var newestOrNot: string

        echo "chkupd v3 Repology backend"

        while true:

                if isEmptyOrWhitespace($request) or $request == "[]":
                        break
                try:
                        newestOrNot = getStr(request[counter]["status"])
                except Exception:
                        echo "Couldn't get package version, skipping"
                        break

                if newestOrNot == "newest":
                        version = getStr(request[counter]["version"])
                        let pkg = parse_runfile(packageDir)
                        echo "local version: "&pkg.version
                        echo "remote version: "&version
                        
                        var isOutdated = false

                        try:
                            let versionInt = replace(version, ".", "")
                            let pkgVersionInt = replace(pkg.version, ".", "")

                            if versionInt > pkgVersionInt:
                                isOutdated = true
                        except Exception:
                            if version > pkg.version:
                                isOutdated = true

                        if isOutdated:
                                echo "Package is not uptodate."

                                if autoUpdate:
                                        autoUpdater(pkg, packageDir, version, skipIfDownloadFails)

                        return
                else:
                        counter = counter+1
