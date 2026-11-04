# RustBB, from its signed release archives (https://rustbb.github.io).
# Written by scripts/formula.sh from rustbb's deploy/homebrew/rustbb.rb.in
# for each release: edits here go with the next one.
class Rustbb < Formula
  desc "Lightweight bulletin board in one executable"
  homepage "https://rustbb.github.io"
  version "0.7.1" # the archives' names end in the architecture, which Homebrew takes for one
  license :cannot_represent # the RustBB License: free to use, binaries only

  on_macos do
    on_arm do
      url "https://github.com/rustbb/releases/releases/download/v0.7.1/rustbb-0.7.1-macos-arm64.tar.gz"
      sha256 "f256869f714e39d6fb4583de1b8105aebcc1aaf1e0275af37be0b258ba9eb592"
    end
    on_intel do
      url "https://github.com/rustbb/releases/releases/download/v0.7.1/rustbb-0.7.1-macos-x86_64.tar.gz"
      sha256 "e3e881d23e144bc4fb3ec14892a17ab5098a959e04160be2d4dd19ba8238c06b"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/rustbb/releases/releases/download/v0.7.1/rustbb-0.7.1-linux-x86_64.tar.gz"
      sha256 "fb664165b575311bc0d6d8b802bb995a86fdedd0f594786a61ecd4779eaa2473"
    end
    on_arm do
      url "https://github.com/rustbb/releases/releases/download/v0.7.1/rustbb-0.7.1-linux-arm64.tar.gz"
      sha256 "15adbb894d75250cb23a48e394efe08bf165d35fd385d5eb2bbbb093e6b1b52f"
    end
  end

  def install
    bin.install "rustbb"
    pkgshare.install "env.example", "deploy"
    doc.install "README.md", "CHANGELOG.md"
    prefix.install "LICENSE", "THIRD-PARTY-LICENSES"
  end

  # The settings, the first time: ones edited since stay. RustBB reads the
  # .env file in the directory it runs in, which the service's is.
  post_install_steps do
    mkdir_p "lib/rustbb", base: :var
    mkdir_p "log", base: :var
    unless_path_exists "rustbb/.env", base: :etc do
      mkdir_p "rustbb", base: :etc
      copy "env.example", "rustbb/.env", source_base: :pkgshare, target_base: :etc
    end
  end

  def caveats
    <<~EOS
      The settings are in #{etc}/rustbb/.env. As a service, RustBB runs the
      forum on http://127.0.0.1:8080/, its database in #{var}/lib/rustbb:
        brew services start rustbb
      Restart it after changing the settings: brew services restart rustbb
      This is for trying RustBB out; a forum on the internet runs on Linux,
      behind a web server (https://rustbb.github.io/deployment/).
    EOS
  end

  service do
    run [opt_bin/"rustbb", "serve"]
    working_dir etc/"rustbb"
    environment_variables RUSTBB_DATABASE_PATH: var/"lib/rustbb/rustbb.db",
                          RUSTBB_UPLOADS_PATH:  var/"lib/rustbb/uploads",
                          RUSTBB_BIND:          "127.0.0.1:8080"
    keep_alive true
    log_path var/"log/rustbb.log"
    error_log_path var/"log/rustbb.log"
  end

  test do
    assert_match "rustbb #{version} ", shell_output("#{bin}/rustbb --version")
    ENV["RUSTBB_DATABASE_PATH"] = (testpath/"forum.db").to_s
    system bin/"rustbb", "migrate"
    assert_path_exists testpath/"forum.db"
  end
end
