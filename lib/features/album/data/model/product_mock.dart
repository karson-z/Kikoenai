class Product {
  final String id;
  final String title;
  final String circle;
  final String imageUrl;
  final List<String> authors;
  final List<String> tags;

  Product({
    required this.id,
    required this.title,
    required this.circle,
    required this.imageUrl,
    required this.authors,
    required this.tags,
  });
}

final List<Product> mockProducts = List.generate(
  20,
  (index) => Product(
    id: 'RJ25029${index + 1}',
    title: '这是一个很长的文本标题，用于演示溢出省略效果 $index',
    circle: '社团名 ${index + 1}',
    imageUrl: 'https://picsum.photos/id/${10 + index}/400/400',
    authors: ['作者A', '作者B'],
    tags: ['标签1', '标签2', '标签3', '长标签4', '标签5', '标签6', '标签7'],
  ),
);
