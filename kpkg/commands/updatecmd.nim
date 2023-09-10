import os
import osproc
import sequtils
import strutils
import ../modules/logger
import ../modules/config

proc update*(repo = "",
    path = "", branch = "master") =
    ## Update repositories

    if not isAdmin():
        err("you have to be root for this action.", false)

    let repodirs = getConfigValue("Repositories", "repoDirs")
    let repolinks = getConfigValue("Repositories", "repoLinks")

    let repoList: seq[tuple[dir: string, link: string]] = zip(repodirs.split(
            " "), repolinks.split(" "))

    for i in repoList:
        if dirExists(i.dir):
            if execShellCmd("git -C "&i.dir&" pull") != 0:
                err("failed to update repositories!", false)
        else:
            if "::" in i.link:
                info "repository on "&i.dir&" not found, cloning them now..."
                discard execProcess("git clone "&i.link.split("::")[0]&" "&i.dir)
                setCurrentDir(i.dir)
                discard execProcess("git checkout "&i.link.split("::")[1])
            else:
                info "repository on "&i.dir&" not found, cloning them now..."
                discard execProcess("git clone "&i.link&" "&i.dir)

    if path != "" and repo != "":
        info "cloning "&path&" from "&repo&"::"&branch
        discard execProcess("git clone "&repo&" "&path)
        if not (repo in repolinks and path in repodirs):
            if branch != "master":
                setCurrentDir(path)
                discard execProcess("git checkout "&branch)
                setConfigValue("Repositories", "repoLinks",
                        repolinks&" "&repo&"::"&branch)
                setConfigValue("Repositories", "repoDirs", repodirs&" "&path)
            else:
                setConfigValue("Repositories", "repoLinks", repolinks&" "&repo)
                setConfigValue("Repositories", "repoDirs", repodirs&" "&path)


    success("updated all repositories", true)
