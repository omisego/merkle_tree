defmodule MerkleTree do
  @moduledoc """
    A hash tree or Merkle tree is a tree in which every non-leaf node is labelled
    with the hash of the labels or values (in case of leaves) of its child nodes.
    Hash trees are useful because they allow efficient and secure verification of
    the contents of large data structures.

      ## Usage Example

  """

  defstruct [:blocks, :root, :hash_function]

  @number_of_children 2 # Number of children per node
  @default_height 16
  @zeroes <<0>> |> List.duplicate(32) |> Enum.join

  @type blocks :: [String.t, ...]
  @type hash_function :: (String.t -> String.t)
  @type height :: non_neg_integer
  @type root :: MerkleTree.Node.t
  @type t :: %MerkleTree{
    blocks: blocks,
    root: root,
    hash_function: hash_function
  }

  @doc """
    Creates a new merkle tree, given a `2^N` number of string blocks and an
    optional hash function.

    By default, `merkle_tree` uses `:sha256` from :crypto.
    Check out `MerkleTree.Crypto` for other available cryptographic hashes.
    Alternatively, you can supply your own hash function that has the spec
    ``(String.t -> String.t)``.
  """
  @spec new(blocks, height, hash_function) :: t
  def new(blocks, hash_function \\ &MerkleTree.Crypto.sha256/1, height \\ @default_height)
  def new(blocks, hash_function, height) do
    root = build(blocks, hash_function, height)
    blocks = blocks |> extend_with_zeroes(height)
    %MerkleTree{blocks: blocks, hash_function: hash_function, root: root}
  end

  defp extend_with_zeroes(blocks, height) do
    extension_length = pow(height) - Enum.count(blocks)
    blocks ++ List.duplicate(@zeroes, extension_length)
  end

  defp pow(n), do: :math.pow(2, n) |> round

  @doc """
    Builds a new binary merkle tree.
  """
  def build(blocks, hash_function, max_height) when blocks != [] do
    height = 0
    leaves = Enum.map(blocks, fn(block) ->
      %MerkleTree.Node{
        value: hash_function.(block),
        children: [],
        height: height
      }
    end)
    extension_node = %MerkleTree.Node{
      value: @zeroes,
      children: [],
      height: height
    }
    _build(leaves, hash_function, height, max_height, extension_node)
  end
  def build([], hash_function, max_height) do
    height = 0
    extension_node = %MerkleTree.Node{
      value: @zeroes,
      children: [],
      height: height
    }
    _build([extension_node], hash_function, height, max_height, extension_node)
  end

  defp _build([root], _, height, max_height, _) when height == max_height, do: root # Base case
  defp _build(nodes, hash_function, height, max_height, extension_node) do # Recursive case
    {nodes, next_extension_node} = nodes |> extend_to_even_length(height, extension_node, hash_function)
    height = height + 1

    children_partitions = Enum.chunk(nodes, @number_of_children)
    parents = Enum.map(children_partitions, fn(partition) ->
      concatenated_values = partition
        |> Enum.map(&(&1.value))
        |> Enum.reduce("", fn(x, acc) -> acc <> x end)
      %MerkleTree.Node{
        value: hash_function.(concatenated_values),
        children: partition,
        height: height
      }
    end)
    _build(parents, hash_function, height, max_height, next_extension_node)
  end

  defp extend_to_even_length(nodes, height, extension_node, hash_function) do
    next_extension_node = %MerkleTree.Node{
      value: hash_function.(extension_node.value <> extension_node.value),
      children: [extension_node, extension_node],
      height: height + 1
    }
    if rem(Enum.count(nodes), 2) == 0 do
      {nodes, next_extension_node}
    else
      {nodes ++ [extension_node], next_extension_node}
    end
  end

end
