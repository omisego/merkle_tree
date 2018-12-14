defmodule MerkleTree do
  @moduledoc """
  Merkle tree is a tree in which every leaf node is labelled 
  with the hash of a data block and every 
  non-leaf node is labelled with the cryptographic 
  hash of the labels of its child nodes

  ## Usage Example
  iex> tree = MerkleTree.new(["1","2","3"], fn v ->"<"<>v<>">" end, 3, "*")
  %MerkleTree{
  height: 3,
  root: %MerkleTree.Node{
    children: {%MerkleTree.Node{
       children: {%MerkleTree.Node{
          children: {%MerkleTree.Node{children: nil, value: "1"},
           %MerkleTree.Node{children: nil, value: "2"}},
          value: "<12>"
        },
        %MerkleTree.Node{
          children: {%MerkleTree.Node{children: nil, value: "3"},
           %MerkleTree.Node{children: nil, value: "*"}},
          value: "<3*>"
        }},
       value: "<<12><3*>>"
     }, %MerkleTree.Node{children: nil, value: "<<**><**>>"}},
    value: "<<<12><3*>><<**><**>>>"
   }
  }
  iex> MerkleTree.proof(tree, 1)
  ["1", "<3*>", "<<**><**>>"] 
  iex> MerkleTree.proof(tree, 3)
  ["3", "<12>", "<<**><**>>"]
  """

  defstruct [:height, :root]
  @type t :: %__MODULE__{height: non_neg_integer, root: Node.t()}

  defmodule Node do
    defstruct [:value, children: nil]
    @type t :: %__MODULE__{children: {t, t} | nil, value: any}
  end

  @doc "Generates proof for a block at a specific index"
  @spec proof(t, non_neg_integer) :: [any]
  def proof(%__MODULE__{height: height, root: root}, integer) do
    list_binary = Integer.digits(integer, 2)
    list_binary = List.duplicate(0, height - length(list_binary)) ++ list_binary

    list_binary |> Enum.reduce({[], root.children}, fn 
      0, {acc, {left, %Node{value: value}}} -> {[value | acc], left.children} 
      1, {acc, {%Node{value: value}, right}} -> {[value | acc], right.children}
    end) |> elem(0)
  end

  def hash_proof(value, {index, proof}, hash_function) do
    list_binary = Integer.digits(index, 2) |> Enum.reverse()
    list_binary = list_binary ++ List.duplicate(0, length(proof) - length(list_binary))
    list_binary |> Enum.reduce({value, proof}, fn
      0,{acc, [head|tail]} -> {hash_function.(acc <> head), tail}
      1,{acc, [head|tail]} -> {hash_function.(head <> acc), tail}
    end) |> elem(0)
  end

  @spec height(list(binary)) :: non_neg_integer
  defp height(list), do: list |> length |> :math.log2() |> :math.ceil() |> round()

  @spec new(list(binary), (binary -> binary)) :: t
  def new(list, hash_function), do: new(list, hash_function, height(list))

  @spec new(list(binary), (binary -> binary), non_neg_integer, any) :: t
  def new(list_leaf, hash_function, height, default_leaf \\ "") do
    list_leaf = Enum.map(list_leaf, fn elem -> %Node{value: elem, children: nil} end)

    {root, default} =
      Enum.reduce(1..height, {list_leaf, default_leaf}, fn
        _, {list, default} ->
          {step(list, hash_function, default), hash_function.(default <> default)}
      end)

    %__MODULE__{height: height, root: hd(root ++ [%Node{value: default}])}
  end

  @spec step(list(binary), (binary -> binary), any) :: t
  defp step(list, hash_function, default_leaf) do
    list
    |> Enum.chunk_every(2)
    |> Enum.map(fn
      [%Node{value: left}, %Node{value: right}] = children ->
        %Node{value: hash_function.(left <> right), children: List.to_tuple(children)}

      [%Node{value: leaf} = node] ->
        %Node{
          value: hash_function.(leaf <> default_leaf),
          children: {node, %Node{value: default_leaf}}
        }
    end)
  end
end
