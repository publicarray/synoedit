workflow "Package" {
  resolves = ["Upload to release"]
  on = "release"
}

action "Build spk" {
  uses = "./.github/actions/build"
  args = ""
}

action "Upload to release" {
  uses = "./.github/actions/upload-release"
  secrets = ["GITHUB_TOKEN"]
  needs = ["Build spk"]
}
