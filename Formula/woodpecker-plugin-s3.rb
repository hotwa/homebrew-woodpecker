class WoodpeckerPluginS3 < Formula
  desc "Woodpecker S3 plugin"
  homepage "https://github.com/woodpecker-ci/plugin-s3"
  license "Apache-2.0"

  url "https://github.com/woodpecker-ci/plugin-s3.git",
      using:  :git,
      branch: "main",
      shallow: false
  version "main"
  head "https://github.com/woodpecker-ci/plugin-s3.git", branch: "main"

  depends_on "go" => :build

  def install
    system "go", "build", "-trimpath", "-o", bin/"plugin-s3", "."
  end

  test do
    output = shell_output("#{bin}/plugin-s3 --help 2>&1", 1)
    assert_match "s3", output.downcase
  end
end
