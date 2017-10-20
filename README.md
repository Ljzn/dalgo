# Dalgo

Some helper macros to write algorithm in "Distributed Algorithm" book.

## 1. Leader Election on a Ring



### Lelann, Chang-Roberts

```elixir
iex> Ring.start LCR, 100  # num of nodes
[LEADER] 100 [ROUND] 101 [MESSAGE] 548
```

### Hirsheberg Sinclair

```elixir
iex> Ring.start HS, 100
[LEADER] 100 [ROUND] 226 [MESSAGE] 2621
```

