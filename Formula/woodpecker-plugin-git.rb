class WoodpeckerPluginGit < Formula
  desc "Woodpecker plugin-git (clone step) for local/exec backend"
  homepage "https://github.com/woodpecker-ci/plugin-git"
  license "Apache-2.0"

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
