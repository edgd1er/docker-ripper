# docker-bake.dev.hcl
target "buildbin" {
  target = "builder"
  context= "."
  dockerfile="Dockerfile"
  args= { FDKVERSION="2.0.3", PREFIX="/usr/local", MKVVERSION="1.18.1", aptCacher="" }
  tags = [
    "builder:latest",
  ]
  platforms = [
    "linux/amd64",
  ]
}

target "final" {
  target = "final"
  context= "."
  dockerfile="Dockerfile"
  args= { aptCacher="" }
  tags = [
    "edgd1er/docker-ripper:latest",
  ]
  platforms = [
    "linux/amd64",
  ]
}