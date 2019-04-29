workflow "Package" {
  on = "release"
  resolves = ["Upload to release"]
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
