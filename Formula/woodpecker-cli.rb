class WoodpeckerCli < Formula
  desc "Official Woodpecker CI command-line client"
  homepage "https://woodpecker-ci.org/"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/woodpecker.git",
      using:  :git,
      revision: "ad2127ef766a25a9645fd2a8680d786b9b9e8f3f"
  version "20260207"
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
