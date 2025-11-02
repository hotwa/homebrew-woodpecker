class WoodpeckerPluginDockerBuildx < Formula
  desc "Woodpecker Docker Buildx plugin binary (for local/exec backend)"
  homepage "https://github.com/woodpecker-ci/plugin-docker-buildx"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/plugin-docker-buildx.git",
      using:  :git,
      revision: "c88f0f4e73add0c48bf99b310db322f0ed396fee"
  version "20251004"
  head "https://github.com/woodpecker-ci/plugin-docker-buildx.git", branch: "main"

  depends_on "go" => :build

  def install
    cd "cmd/docker-buildx" do
      system "go", "build", "-trimpath", *std_go_args(output: bin/"plugin-docker-buildx")
    end
    bin.install_symlink "plugin-docker-buildx" => "woodpecker-plugin-docker-buildx"
  end

  test do
    out = shell_output("#{bin}/plugin-docker-buildx --help 2>&1", 1)
    assert_match "usage", out.downcase
  end
end
