class WoodpeckerCli < Formula
  desc "Official Woodpecker CI command-line client"
  homepage "https://woodpecker-ci.org/"
  license "Apache-2.0"

  head "https://github.com/woodpecker-ci/woodpecker.git", branch: "main"

  depends_on "go" => :build

  def install
    cd "cmd/cli" do
      system "go", "build", "-trimpath", *std_go_args(output: bin/"woodpecker-cli")
    end
  end

  test do
    out = shell_output("#{bin}/woodpecker-cli --help 2>&1")
    assert_match "woodpecker-cli", out
  end
end
