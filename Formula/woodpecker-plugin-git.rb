class WoodpeckerPluginGit < Formula
  desc "Woodpecker plugin-git (clone step) for local/exec backend"
  homepage "https://github.com/woodpecker-ci/plugin-git"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/plugin-git.git",
      using:  :git,
      revision: "46c36eb4b313c59ce1345556085d95ed2fbf415a"
  version "20251004"
  head "https://github.com/woodpecker-ci/plugin-git.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", *std_go_args(output: bin/"plugin-git")
  end

  test do
    output = shell_output("#{bin}/plugin-git --help 2>&1", 1)
    assert_match "usage", output.downcase
  end
end
