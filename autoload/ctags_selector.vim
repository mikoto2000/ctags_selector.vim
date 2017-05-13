let g:caller_window_id = ''

function ctags_selector#OpenTagSelector()
    " レジスタ保存
    let tmp = @"

    " カーソル下のワードを記憶
    normal viwy

    """ 変数 taglist に ``:tselect`` の結果を格納
    let taglist=""
    redir => taglist
    execute "silent tselect " . @"
    redir END

    " 呼び出し元のウィンドウ ID を記憶
    let g:caller_window_id = win_getid()

    " 新しいバッファを作成
    if bufexists(bufnr('__CTAGS_SELECTOR_TAG_LIST__'))
        bwipeout! __CTAGS_SELECTOR_TAG_LIST__
    endif
    silent bo new __CTAGS_SELECTOR_TAG_LIST__

    " タグファイルリスト取得
    let tag_files = tagfiles()

    " タグファイルの内容を読み込む
    silent put!=taglist
    normal Gdddd0ggjldggdd

    " レジスタ復元
    let @" = tmp

    """ バッファリスト用バッファの設定
    setlocal noshowcmd
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nobuflisted
    setlocal nomodifiable
    setlocal wrap
    setlocal nonumber
    setlocal filetype=tags

    """ 選択したバッファに移動
    map <buffer> <Return> :call ctags_selector#OpenBuffer()<Return>

    """ バッファリストを閉じる
    map <buffer> q :call ctags_selector#CloseTagSelector()<Return>
endfunction

function ctags_selector#CloseTagSelector()
    """ バッファリストを閉じる
    :bwipeout!

    """ 呼び出し元ウィンドウをアクティブにする
    call win_gotoid(g:caller_window_id)
endfunction

function ctags_selector#OpenBuffer()
    if line('.') == 1
        return
    endif

    let tag_info = ctags_selector#GetTagInfo()
    let number = tag_info["number"]
    let symbol_name = tag_info["symbol"]
    :bwipeout!

    """ 呼び出し元ウィンドウをアクティブにする
    call win_gotoid(g:caller_window_id)

    """ タグジャンプ
    execute ":" . number . "tag " . symbol_name
endfunction

function ctags_selector#GetTagInfo()
    " タグリストのナンバーを検索
    " 今いる行の先頭がうまく検索対象に入らないのでとりあえず次行に移動してる。
    normal j
    execute '?^\d'

    " 行を記憶
    let row = line('.')
    let line = getline(row)

    " symbol 取得
    normal gg0
    execute '/tag'
    normal n
    let tag_start_col = col('.')
    execute 'normal ' . row . 'gg'
    execute 'normal ' . (tag_start_col) . 'le'
    let tag_end_col = col('.')
    let symbol = line[tag_start_col - 1 : tag_end_col]

    " number 取得
    let line = substitute(line, '\s\+', ' ', 'g')
    let splited_line = split(line, ' ')
    let number = get(splited_line, 0)

    return {'number' : number, 'symbol' : symbol}
endfunction
