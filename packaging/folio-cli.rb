class FolioCli < Formula
  desc "A modern, fast CLI application for the Hungarian Kreta e-diary system."
  homepage "https://github.com/CsPS0/folio-cli"
  url "https://github.com/CsPS0/folio-cli/releases/download/v1.0.0/folio-cli-linux"
  sha256 "PUT_SHA256_HASH_HERE"
  license "MIT"
  version "1.0.0"

  def install
    bin.install "folio-cli-linux" => "folio-cli"
  end

  test do
    system "#{bin}/folio-cli", "--help"
  end
end
