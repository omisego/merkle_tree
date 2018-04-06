defmodule MerkleTreeTest do
  use ExUnit.Case
  doctest MerkleTree

  test "primary use case" do
    {:ok, f} = MerkleTree.new(['a', 'b', 'c', 'd'], &MerkleTree.Crypto.sha256/1, 2)
    assert f.root.value == "58c89d709329eb37285837b042ab6ff72c7c8f74de0446b091b6a0131c102cfd"

    {:ok, f} = MerkleTree.new(['a', 'b', 'c'], &MerkleTree.Crypto.sha256/1, 2)
    assert f.root.value == "5b2441d1eb763fa7e87908d8cd62706dfea2ae058a4edf9053b05ec4c52b42c8"
  end

  test "calculates merkle tree for empty blocks" do
    {:ok, f} = MerkleTree.new([], &MerkleTree.Crypto.sha256/1, 2)
    assert f.root.value == "ade4faf1929c62d0b2c19f9ac9641f8cf009923d09e85cc3e3a560157cc4e0ac"
  end

end
