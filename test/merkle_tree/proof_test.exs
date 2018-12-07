defmodule MerkleTree.ProofTest do
  use ExUnit.Case

  def hash(value), do: :crypto.hash(:sha256, value) |> Base.encode16(case: :lower)
  def hash_function(v1, v2), do: hash(v1 <> v2)

  test "correct proofs" do
    blocks = ~w/a b c d e f g h/ |> Enum.map(&hash/1)
      tree = MerkleTree.new(blocks, &hash_function/2, 3)

    assert blocks
             |> Enum.with_index
    |> Enum.map(fn {value, idx} ->{value, idx, MerkleTree.proof(tree, idx)} end)
    |> Enum.map(fn {value, idx, proof} -> 
      MerkleTree.hash_proof(value, {idx,proof}, &hash_function/2) == tree.root.value
      end)
    |> Enum.all? 
  end

  test "incorrect proof" do
    blocks = ~w/a b c d e f g h/ |> Enum.map(&hash/1)
    tree = MerkleTree.new(blocks, &hash_function/2, 3)
    proof = MerkleTree.proof(tree, 5)

    # test sanity
    assert MerkleTree.hash_proof(hash("f"), {5,proof}, &hash_function/2) == tree.root.value

    # bad index
    assert MerkleTree.hash_proof(hash("f"), {6,proof}, &hash_function/2) != tree.root.value

    catch_error MerkleTree.calc_hash(hash("f"), {5, tl(proof)}, &hash_function/2)

    # different hash function
    different_hash = fn a, b -> :crypto.hash(:sha224, a <> b) |> Base.encode16(case: :lower) end

    assert MerkleTree.hash_proof(hash("f"), {5, proof}, different_hash) != tree.root.value

    assert MerkleTree.hash_proof(hash("f"),{5, [hash("z") | tl(proof)]}, &hash_function/2) != tree.root.value

    # corrupted root hash
    assert MerkleTree.hash_proof(hash("f"), {5, proof}, &hash_function/2) !=  hash("z")
  end
end
