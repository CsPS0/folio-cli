class FolioCli < Formula
  desc "Terminal-based client for the Hungarian Kréta electronic school diary system"
  homepage "https://github.com/CsPS0/folio-cli"
  version "1.2.3"
  license "MIT"

  on_macos do
    url "https://github.com/CsPS0/folio-cli/releases/download/v1.2.3/folio-cli-macos"
    sha256 "ccb33490ccf85b7f4541b67f0e4cd1a921e7450553243ab60d241ea8b957d3c0"
  end

  on_linux do
    url "https://github.com/CsPS0/folio-cli/releases/download/v1.2.3/folio-cli-linux"
    sha256 "cd9737fd23a72483d6e2b6b8e9078d2737e0d07a6f1a01617f6bf615a1529f06"
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
