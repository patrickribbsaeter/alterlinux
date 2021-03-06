# チャンネルをAlterISO3用に書き換える

AlterISO3では様々な新機能が追加されました。そしてそれと同時に一部の仕様も変更されています。  

ここではAlterISO2用に開発されたチャンネルを3用に更新するための手順を説明します。  

## この文書の読み方

ここではチャンネル名を`<ch_name>`と表記しています。それぞれのチャンネルディレクトリに置き換えてください。  

## 1. バージョンファイルを作成する

`<ch_name>/alteriso`ファイルを作成し、中に`alteriso=3.0`と記述して下さい。  

このファイルが存在しないと以前のバージョン用のチャンネルと解釈され、ビルドできません。  

## 2. 日本語関連のコードを変更する

### config.<arch>

以前の`japanese`変数は意味を成しません。AlterISO3では言語名を`locale_name`変数で行っています。  
特定の言語を強制的に使用させたい場合は、`-l`オプションで指定する言語名を`locale_name`変数で指定して下さい。  

#### 詳細設定を行う
AlterISO3は`locale_name`の値を元にいくつかの変数を`system/locale-<arch>`から参照します。  
チャンネルの`config`ファイルでは変数を上書きできるので、これらを詳細に書き換えることができます。  
`locale.gen`の値は`locale_gen_name`変数、タイムゾーンは`locale_time`変数で設定できます。  
詳細は[releng](/channels/releng/config.any)を参考にして下さい。  

### customize_airootfs_<ch_name>.sh

#### 引数解析

引数解析部分が大きく変更されています。以下の指示に従って書き換えて下さい。  

そのまま書き換えを行い、コードは変更しないでください。  

##### 以前のコード

```bash
# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel='zen'
theme_name=alter-logo
rebuild=false
japanese=false
username='alter'
os_name="Alter Linux"
install_dir="alter"
usershell="/bin/bash"
debug=true


# Parse arguments
while getopts 'p:bt:k:rxju:o:i:s:da:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel="${OPTARG}" ;;
        r) rebuild=true ;;
        j) japanese=true;;
        u) username="${OPTARG}" ;;
        o) os_name="${OPTARG}" ;;
        i) install_dir="${OPTARG}" ;;
        s) usershell="${OPTARG}" ;;
        d) debug=true ;;
        x) debug=true; set -xv ;;
        a) arch="${OPTARG}"
    esac
done
```

##### AlterISO3のコード（2020年7月31日現在）

```bash
# Default value
# Default value
# All values can be changed by arguments.
password=alter
boot_splash=false
kernel_config_line=("zen" "vmlinuz-linux-zen" "linux-zen")
theme_name=alter-logo
rebuild=false
username='alter'
os_name="Alter Linux"
install_dir="alter"
usershell="/bin/bash"
debug=false
timezone="UTC"
localegen="en_US\\.UTF-8\\"
language="en"


# Parse arguments
while getopts 'p:bt:k:rxu:o:i:s:da:g:z:l:' arg; do
    case "${arg}" in
        p) password="${OPTARG}" ;;
        b) boot_splash=true ;;
        t) theme_name="${OPTARG}" ;;
        k) kernel_config_line=(${OPTARG}) ;;
        r) rebuild=true ;;
        u) username="${OPTARG}" ;;
        o) os_name="${OPTARG}" ;;
        i) install_dir="${OPTARG}" ;;
        s) usershell="${OPTARG}" ;;
        d) debug=true ;;
        x) debug=true; set -xv ;;
        a) arch="${OPTARG}" ;;
        g) localegen="${OPTARG/./\\.}\\" ;;
        z) timezone="${OPTARG}" ;;
        l) language="${OPTARG}" ;;
    esac
done


# Parse kernel
kernel="${kernel_config_line[0]}"
kernel_filename="${kernel_config_line[1]}"
kernel_mkinitcpio_profile="${kernel_config_line[2]}"
```

#### 日本語用処理部分

日本語化のために、以前は`japanese`変数が`true`か`false`かで処理を分岐させていました。  

しかしAlterISO3では`japanese`変数は廃止されているため正常に処理を続行できません。  

代わりに`language`変数が`ja`に設定されているかどうかで処理を分岐させてください。  

##### 例

```bash

# 以前のコード

if [[ "${japanese}" = true ]]; then

# AlterISO3用のコード

if [[ "${language}" = "ja" ]]; then

```

## 3.パッケージリストのパスを変更する

多言語化に伴い`jp.<arch>`と`non-jp.<arch>`のパッケージリストは廃止されました。  

これらはAlterISOでは通常のパッケージリストと同等に扱われてしまいます。  

以前のように言語ごとのパッケージを追加する場合は`<ch_name>/packages.<arch>/lang/<lang_name>.<arch>`リストを使用して下さい。  
