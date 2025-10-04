class WoodpeckerPluginDockerBuildx < Formula
  desc "Woodpecker Docker Buildx plugin"
  homepage "https://github.com/woodpecker-ci/plugin-docker-buildx"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/plugin-docker-buildx.git",
      using:  :git,
      branch: "main",
      shallow: false
  version "main"
  head "https://github.com/woodpecker-ci/plugin-docker-buildx.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", "-o", bin/"plugin-docker-buildx", "."
  end

  test do
    output = shell_output("#{bin}/plugin-docker-buildx --help 2>&1", 1)
    assert_match "buildx", output.downcase
  end
end
