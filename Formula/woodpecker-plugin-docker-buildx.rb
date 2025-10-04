class WoodpeckerPluginDockerBuildx < Formula
  desc "Woodpecker Docker Buildx plugin binary (for local/exec backend)"
  homepage "https://github.com/woodpecker-ci/plugin-docker-buildx"
  license "Apache-2.0"

  head "https://github.com/woodpecker-ci/plugin-docker-buildx.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", *std_go_args(output: bin/"plugin-docker-buildx")
  end

  test do
    out = shell_output("#{bin}/plugin-docker-buildx --help 2>&1", 1)
    assert_match "usage", out.downcase
  end
end
