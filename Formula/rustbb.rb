# RustBB, from its signed release archives (https://rustbb.github.io).
# Written by scripts/formula.sh from rustbb's deploy/homebrew/rustbb.rb.in
# for each release: edits here go with the next one.
class Rustbb < Formula
  desc "Lightweight bulletin board in one executable"
  homepage "https://rustbb.github.io"
  version "0.7.0" # the archives' names end in the architecture, which Homebrew takes for one
  license :cannot_represent # the RustBB License: free to use, binaries only

  on_macos do
    on_arm do
      url "https://github.com/rustbb/releases/releases/download/v0.7.0/rustbb-0.7.0-macos-arm64.tar.gz"
      sha256 "8e9f3252f3e3a2344c92403b95c62f4c03b006e9d649e80cc5f2bfbf6e05d7d7"
    end
    on_intel do
      url "https://github.com/rustbb/releases/releases/download/v0.7.0/rustbb-0.7.0-macos-x86_64.tar.gz"
      sha256 "d21d86c8ba01ef3c1b2ca79394aef751ee982b4976976bce67f42bbdc935374c"
    end
  end

  on_linux do
    on_intel do
      url "https://github.com/rustbb/releases/releases/download/v0.7.0/rustbb-0.7.0-linux-x86_64.tar.gz"
      sha256 "021b357f5bbf6bb77a2fd858b3772e8ab7da8fa9d9f1d19f38cf788fbb6cb425"
    end
    on_arm do
      url "https://github.com/rustbb/releases/releases/download/v0.7.0/rustbb-0.7.0-linux-arm64.tar.gz"
      sha256 "7a899cd8c4d26e94a1dc961121b73d81abe3fc255ebd06f320b34954c13dd46f"
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
