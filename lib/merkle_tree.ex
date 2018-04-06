defmodule MerkleTree do
  @moduledoc """
    A hash tree or Merkle tree is a tree in which every non-leaf node is labelled
    with the hash of the labels or values (in case of leaves) of its child nodes.
    Hash trees are useful because they allow efficient and secure verification of
    the contents of large data structures.

      ## Usage Example

      iex> MerkleTree.new(['a', 'b', 'c', 'd'], &MerkleTree.Crypto.sha256/1, 2)
      {:ok, %MerkleTree{blocks: ['a', 'b', 'c', 'd'], hash_function: &MerkleTree.Crypto.sha256/1,
            root: %MerkleTree.Node{children: [%MerkleTree.Node{children: [%MerkleTree.Node{children: [], height: 0,
                 value: "ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb"},
                %MerkleTree.Node{children: [], height: 0, value: "3e23e8160039594a33894f6564e1b1348bbd7a0088d42c4acb73eeaed59c009d"}], height: 1,
               value: "62af5c3cb8da3e4f25061e829ebeea5c7513c54949115b1acc225930a90154da"},
              %MerkleTree.Node{children: [%MerkleTree.Node{children: [], height: 0,
                 value: "2e7d2c03a9507ae265ecf5b5356885a53393a2029d241394997265a1a25aefc6"},
                %MerkleTree.Node{children: [], height: 0, value: "18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4"}], height: 1,
               value: "d3a0f1c792ccf7f1708d5422696263e35755a86917ea76ef9242bd4a8cf4891a"}], height: 2,
             value: "58c89d709329eb37285837b042ab6ff72c7c8f74de0446b091b6a0131c102cfd"}}}
  """

  defstruct [:blocks, :root, :hash_function]

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
  @spec new(blocks, hash_function, height) :: {:ok, t} | {:error, atom}
  def new(blocks, hash_function \\ &MerkleTree.Crypto.sha256/1, height \\ @default_height) do
    case build(blocks, hash_function, height) do
      {:ok, root} ->
        blocks = blocks |> extend_with_zeroes(height)
        {:ok, %MerkleTree{blocks: blocks, hash_function: hash_function, root: root}}
      error -> error
    end
  end

  defp extend_with_zeroes(blocks, height) do
    extension_length = pow(height) - Enum.count(blocks)
    blocks ++ List.duplicate(@zeroes, extension_length)
  end

  defp pow(n), do: :math.pow(2, n) |> round

  @doc """
    Builds a new binary merkle tree.
  """
  def build([], hash_function, max_height) do
    height = 0
    extension_node = %MerkleTree.Node{
      value: @zeroes,
      children: [],
      height: height
    }
    {:ok, _build([extension_node], hash_function, height, max_height, extension_node)}
  end
  def build(blocks, hash_function, max_height) do
    if Enum.count(blocks) > pow(max_height) do
      {:error, :too_many_blocks}
    else
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
      {:ok, _build(leaves, hash_function, height, max_height, extension_node)}
    end
  end

  defp _build([root], _, height, max_height, _) when height == max_height, do: root # Base case
  defp _build(nodes, hash_function, height, max_height, extension_node) do # Recursive case
    {nodes, next_extension_node} = nodes |> extend_to_even_length(height, extension_node, hash_function)
    height = height + 1

    children_partitions = Enum.chunk(nodes, 2)
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
