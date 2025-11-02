class WoodpeckerPluginS3 < Formula
  desc "Woodpecker S3 plugin binary (for local/exec backend)"
  homepage "https://github.com/woodpecker-ci/plugin-s3"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/plugin-s3.git",
      using:  :git,
      revision: "2ae7f91e6586d533d1b3058ac4bca292a5c5ada9"
  version "20251004"
  head "https://github.com/woodpecker-ci/plugin-s3.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", *std_go_args(output: bin/"plugin-s3")
    bin.install_symlink "plugin-s3" => "woodpecker-plugin-s3"
  end

  test do
    out = shell_output("#{bin}/plugin-s3 --help 2>&1", 1)
    assert_match "usage", out.downcase
  end
end
