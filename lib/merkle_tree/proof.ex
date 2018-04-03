defmodule MerkleTree.Proof do
  @moduledoc """
    Generate and verify merkle proofs
  """
  defstruct [:hashes, :hash_function]

  @type t :: %MerkleTree.Proof{
    hashes: [String.t, ...],
    # TODO: remove when deprecated MerkleTree.Proof.proven?/3 support ends
    hash_function: MerkleTree.hash_function
  }

  @doc """
  Generates proof for a block at a specific index
  """
  @spec prove(MerkleTree.t, non_neg_integer) :: t
  def prove(%MerkleTree{root: %MerkleTree.Node{height: height} = root} = tree,
            index) do
    %MerkleTree.Proof{
      hashes: _prove(root, binarize(index, height)),
      # TODO: remove when deprecated MerkleTree.Proof.proven?/3 support ends
      hash_function: tree.hash_function
    }
  end

  defp _prove(_, ""), do: []
  defp _prove(%MerkleTree.Node{children: children},
              index_binary) do
    {path_head, path_tail} = path_from_binary(index_binary)
    [child, sibling] = case path_head do
      1 -> Enum.reverse(children)
      0 -> children
    end
    [sibling.value] ++ _prove(child, path_tail)
  end

  @doc """
  Verifies proof for a block at a specific index
  """
  @spec proven?({String.t, non_neg_integer}, String.t, MerkleTree.hash_function, t) :: boolean
  def proven?({block, index}, root_hash, hash_function,
              %MerkleTree.Proof{hashes: proof}) do
    height = length(proof)
    root_hash == _hash_proof(block, binarize(index, height), proof, hash_function)
  end

  @doc false
  @deprecated "Use proven?/4 instead"
  # TODO: remove when deprecated MerkleTree.Proof.proven?/3 support ends
  def proven?({block, index}, root_hash,
              %MerkleTree.Proof{hashes: proof, hash_function: hash_function}) do
    height = length(proof)
    root_hash == _hash_proof(block, binarize(index, height), proof, hash_function)
  end

  defp _hash_proof(block, "", [], hash_function) do
    hash_function.(block)
  end
  defp _hash_proof(block, index_binary, [proof_head | proof_tail], hash_function) do
    {path_head, path_tail} = path_from_binary(index_binary)
    case path_head do
      1 -> hash_function.(
        proof_head <> _hash_proof(block, path_tail, proof_tail, hash_function)
      )
      0 -> hash_function.(
        _hash_proof(block, path_tail, proof_tail, hash_function) <> proof_head
      )
    end
  end

  @spec binarize(integer, integer) :: binary
  defp binarize(index, height) do
    <<index_binary::binary-unit(1)>> = <<index::unsigned-big-integer-size(height)>>
    index_binary
  end

  @spec path_from_binary(binary) :: {binary, binary}
  defp path_from_binary(index_binary) do
    <<path_head::unsigned-big-integer-unit(1)-size(1),
    path_tail::binary-unit(1)>> = index_binary
    {path_head, path_tail}
  end
end
