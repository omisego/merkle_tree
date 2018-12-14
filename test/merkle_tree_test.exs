defmodule MerkleTreeTest do
  use ExUnit.Case
  doctest MerkleTree

  def hash(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  @zero <<0>> |> List.duplicate(32) |> Enum.join()

  test "primary use case" do
    leaf = ['a', 'b', 'c', 'd'] |> Enum.map(&hash/1)
    f = MerkleTree.new(leaf, &hash/1)
    assert f.root.value == "58c89d709329eb37285837b042ab6ff72c7c8f74de0446b091b6a0131c102cfd"

    f =
      MerkleTree.new(['a', 'b', 'c'] |> Enum.map(&hash/1), &hash/1, 2, @zero)

    assert f.root.value == "5b2441d1eb763fa7e87908d8cd62706dfea2ae058a4edf9053b05ec4c52b42c8"
  end

  test "calculates merkle tree for empty blocks" do
    %MerkleTree{root: root} = MerkleTree.new([], &hash/1, 2, @zero)
    assert root.value == "ade4faf1929c62d0b2c19f9ac9641f8cf009923d09e85cc3e3a560157cc4e0ac"
  end
end
