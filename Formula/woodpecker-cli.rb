class WoodpeckerCli < Formula
  desc "Official Woodpecker CI command-line client"
  homepage "https://woodpecker-ci.org/"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/woodpecker.git",
      using:  :git,
      revision: "9627495a3d78a8df8bb18122d6a65aa0aac1a24d"
  version "20260118"
  head "https://github.com/woodpecker-ci/woodpecker.git", branch: "main"

  depends_on "go" => :build

  def install
    cd "cmd/cli" do
      system "go", "build", "-trimpath", *std_go_args(output: bin/"woodpecker")
    end
    bin.install_symlink "woodpecker" => "woodpecker-cli"
  end

  test do
    out = shell_output("#{bin}/woodpecker --help 2>&1")
    assert_match "woodpecker", out
  end
end
