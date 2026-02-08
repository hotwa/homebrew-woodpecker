class WoodpeckerCli < Formula
  desc "Official Woodpecker CI command-line client"
  homepage "https://woodpecker-ci.org/"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/woodpecker.git",
      using:  :git,
      revision: "de6614046e75d4875a2b84ce69691789fce3c8c3"
  version "20260208"
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
