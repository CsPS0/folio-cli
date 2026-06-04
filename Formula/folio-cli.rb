class FolioCli < Formula
  desc "Terminal-based client for the Hungarian Kréta electronic school diary system"
  homepage "https://github.com/CsPS0/folio-cli"
  version "1.0.2"
  license "MIT"

  on_macos do
    url "https://github.com/CsPS0/folio-cli/releases/download/v1.0.2/folio-cli-macos"
    sha256 "0000000000000000000000000000000000000000000000000000000000000000"
  end

  on_linux do
    url "https://github.com/CsPS0/folio-cli/releases/download/v1.0.2/folio-cli-linux"
    sha256 "a2fa26b22c19735fddbc802221b04f62cd462443df381be2df650000c213aadf"
  end

  def install
    if OS.mac?
      bin.install "folio-cli-macos" => "folio-cli"
    elsif OS.linux?
      bin.install "folio-cli-linux" => "folio-cli"
    end
  end

  test do
    system "#{bin}/folio-cli", "--help"
  end
end
