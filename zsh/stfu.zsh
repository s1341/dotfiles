function stfu {
    $@ >/dev/null 2>&1 &
    disown %%
}
