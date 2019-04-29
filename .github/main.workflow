workflow "Package" {
  resolves = ["Upload to release"]
  on = "release"
}

action "Build spk" {
  uses = "./.github/actions/build"
}

action "Upload to release" {
  uses = "./.github/actions/upload-release"
  args = "spk"
  secrets = ["GITHUB_TOKEN"]
  needs = ["Build spk"]
}
