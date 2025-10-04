class WoodpeckerCli < Formula
  desc "Woodpecker command-line client"
  homepage "https://woodpecker-ci.org/"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/woodpecker.git",
      using:  :git,
      tag:    "v3.10.0",
      shallow: false
  head "https://github.com/woodpecker-ci/woodpecker.git", branch: "main"

  depends_on "go" => :build

  def install
    cd "cmd/cli" do
      system "go", "build", "-trimpath", "-o", bin/"woodpecker"
    end
  end

  test do
    assert_match "woodpecker", shell_output("#{bin}/woodpecker --help")
  end
end
