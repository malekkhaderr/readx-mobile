/// Mock data for the Book Shop feature.
/// Each book has pricing, badges, sample text, and metadata for the store UI.

class ShopBook {
  final String id;
  final String title;
  final String author;
  final String coverImage;
  final double price;
  final double? discountPrice;
  final double rating;
  final int reviewCount;
  final String genre;
  final String description;
  final int pageCount;
  final String readingTime;
  final List<String> tags;
  final bool isBestseller;
  final bool isNew;
  final bool isTrending;
  final String sampleText;

  const ShopBook({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.price,
    this.discountPrice,
    required this.rating,
    required this.reviewCount,
    required this.genre,
    required this.description,
    required this.pageCount,
    required this.readingTime,
    this.tags = const [],
    this.isBestseller = false,
    this.isNew = false,
    this.isTrending = false,
    this.sampleText = '',
  });

  /// Effective price (discount if available)
  double get effectivePrice => discountPrice ?? price;

  /// Whether there is an active sale
  bool get isOnSale => discountPrice != null && discountPrice! < price;

  /// Primary badge to show on card
  String? get badge {
    if (isOnSale) return 'Sale';
    if (isTrending) return 'Trending';
    if (isBestseller) return 'Bestseller';
    if (isNew) return 'New';
    return null;
  }
}

// ── Categories ────────────────────────────────────────────────
enum BookCategory {
  all('All'),
  bestSellers('Best Sellers'),
  newReleases('New Releases'),
  fiction('Fiction'),
  mystery('Mystery'),
  romance('Romance'),
  fantasy('Fantasy'),
  classics('Classics'),
  selfHelp('Self-Help'),
  youngAdult('Young Adult');

  final String label;
  const BookCategory(this.label);
}

// ── Sort Options ──────────────────────────────────────────────
enum BookSortOption {
  popular('Popular'),
  newest('Newest'),
  highestRated('Highest Rated'),
  priceLowHigh('Price: Low to High'),
  priceHighLow('Price: High to Low');

  final String label;
  const BookSortOption(this.label);
}

// ── Mock Data ─────────────────────────────────────────────────
class MockBookShopData {
  static const List<ShopBook> allBooks = [
    // ── Fiction ────────────────────────────────────────────
    ShopBook(
      id: 'sb1',
      title: 'The Invisible Life of Addie LaRue',
      author: 'V.E. Schwab',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780765387561-L.jpg',
      price: 14.99,
      discountPrice: 9.99,
      rating: 4.6,
      reviewCount: 12840,
      genre: 'Fiction',
      description: 'A life no one will remember. A story you will never forget. France, 1714: a young woman makes a Faustian bargain to live forever—and is cursed to be forgotten by everyone she meets.',
      pageCount: 448,
      readingTime: '7h 28m',
      tags: ['Fiction', 'Fantasy', 'Best Sellers'],
      isBestseller: true,
      isTrending: true,
      sampleText: 'A girl is growing in the garden.\n\nRather, the birth of her was the event that started this particular garden growing—the birth of Adeline LaRue. She was born on March 10, 1691, in the village of Villon-sur-Sarthe in France, just after midnight, on the cusp of a new day.',
    ),
    ShopBook(
      id: 'sb2',
      title: 'Where the Crawdads Sing',
      author: 'Delia Owens',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780735219090-L.jpg',
      price: 12.99,
      rating: 4.7,
      reviewCount: 28500,
      genre: 'Fiction',
      description: 'For years, rumors of the "Marsh Girl" haunted Barkley Cove, a quiet town on the North Carolina coast. So in late 1969, when handsome Chase Andrews is found dead, the locals immediately suspect Kya Clark.',
      pageCount: 368,
      readingTime: '6h 8m',
      tags: ['Fiction', 'Mystery', 'Best Sellers'],
      isBestseller: true,
      sampleText: 'Marsh is not swamp. Marsh is a space of light, where grass grows in water, and water flows into the sky. Slow-moving creeks wander, carrying the essence of all that comes and goes.',
    ),
    ShopBook(
      id: 'sb3',
      title: 'The Seven Husbands of Evelyn Hugo',
      author: 'Taylor Jenkins Reid',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781501161933-L.jpg',
      price: 11.99,
      rating: 4.5,
      reviewCount: 19200,
      genre: 'Fiction',
      description: 'Aging and reclusive Hollywood movie icon Evelyn Hugo is finally ready to tell the truth about her glamorous and scandalous life.',
      pageCount: 389,
      readingTime: '6h 29m',
      tags: ['Fiction', 'Romance'],
      isTrending: true,
      sampleText: 'When I was told that Evelyn Hugo wanted to give her interview to me, I thought it was a joke. Or maybe I just hoped it was a joke.',
    ),

    // ── Mystery ───────────────────────────────────────────
    ShopBook(
      id: 'sb4',
      title: 'The Silent Patient',
      author: 'Alex Michaelides',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781250301697-L.jpg',
      price: 13.99,
      rating: 4.4,
      reviewCount: 22100,
      genre: 'Mystery',
      description: 'Alicia Berenson lived a seemingly perfect life until one evening, when she shot her husband five times in the face. She never spoke another word.',
      pageCount: 325,
      readingTime: '5h 25m',
      tags: ['Mystery', 'Best Sellers'],
      isBestseller: true,
      sampleText: 'Alicia Berenson was thirty-three years old when she killed her husband. She shot him five times in the face with a pistol, and then she never spoke another word.',
    ),
    ShopBook(
      id: 'sb5',
      title: 'The Maid',
      author: 'Nita Prose',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780593356159-L.jpg',
      price: 14.99,
      discountPrice: 10.99,
      rating: 4.3,
      reviewCount: 8900,
      genre: 'Mystery',
      description: 'Molly Gray is a maid at a five-star hotel. When she finds a guest dead in his room, she becomes the prime suspect.',
      pageCount: 304,
      readingTime: '5h 4m',
      tags: ['Mystery', 'New Releases'],
      isNew: true,
      sampleText: 'I am your maid. I am the one who cleans your room. I know everything about you—what you eat, what you drink, what you leave behind.',
    ),
    ShopBook(
      id: 'sb6',
      title: 'Gone Girl',
      author: 'Gillian Flynn',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780307588371-L.jpg',
      price: 10.99,
      rating: 4.5,
      reviewCount: 35200,
      genre: 'Mystery',
      description: 'On a warm summer morning in North Carthage, Missouri, it is Nick and Amy Dunne\'s fifth wedding anniversary. Amy has disappeared.',
      pageCount: 422,
      readingTime: '7h 2m',
      tags: ['Mystery', 'Best Sellers'],
      isBestseller: true,
      sampleText: 'When I think of my wife, I always think of her head. The shape of it, to begin with. The very first time I saw her, it was the back of the head I saw.',
    ),

    // ── Romance ───────────────────────────────────────────
    ShopBook(
      id: 'sb7',
      title: 'It Ends with Us',
      author: 'Colleen Hoover',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781501110368-L.jpg',
      price: 12.99,
      rating: 4.6,
      reviewCount: 42300,
      genre: 'Romance',
      description: 'Lily hasn\'t always had it easy, but that\'s never stopped her from working hard for the life she wants. When she feels a spark with a neurosurgeon named Ryle, everything changes.',
      pageCount: 376,
      readingTime: '6h 16m',
      tags: ['Romance', 'Best Sellers'],
      isBestseller: true,
      isTrending: true,
      sampleText: 'There is no such thing as bad people. We\'re all just people who sometimes do bad things.',
    ),
    ShopBook(
      id: 'sb8',
      title: 'Beach Read',
      author: 'Emily Henry',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781984806734-L.jpg',
      price: 11.99,
      discountPrice: 8.99,
      rating: 4.3,
      reviewCount: 11400,
      genre: 'Romance',
      description: 'Two writers with opposite genres swap styles for the summer in this witty, romantic comedy about finding love in unexpected places.',
      pageCount: 361,
      readingTime: '6h 1m',
      tags: ['Romance', 'New Releases'],
      isNew: true,
      sampleText: 'Once upon a time, a boy and a girl fell in love. But this is not that story. This is the story that comes after.',
    ),
    ShopBook(
      id: 'sb9',
      title: 'The Notebook',
      author: 'Nicholas Sparks',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781455582877-L.jpg',
      price: 9.99,
      rating: 4.4,
      reviewCount: 18600,
      genre: 'Romance',
      description: 'Set amid the austere beauty of coastal North Carolina, this is the story of Noah Calhoun and Allie Nelson, two young lovers who are torn apart by fate.',
      pageCount: 214,
      readingTime: '3h 34m',
      tags: ['Romance', 'Classics'],
      sampleText: 'Who am I? And how, I wonder, will this story end? The sun has come up and I am sitting by a window.',
    ),

    // ── Fantasy ───────────────────────────────────────────
    ShopBook(
      id: 'sb10',
      title: 'The Name of the Wind',
      author: 'Patrick Rothfuss',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780756404741-L.jpg',
      price: 15.99,
      rating: 4.8,
      reviewCount: 26400,
      genre: 'Fantasy',
      description: 'Told in Kvothe\'s own voice, this is the tale of the magically gifted young man who grows to be the most notorious wizard his world has ever seen.',
      pageCount: 662,
      readingTime: '11h 2m',
      tags: ['Fantasy', 'Best Sellers'],
      isBestseller: true,
      sampleText: 'It was night again. The Waystone Inn lay in silence, and it was a silence of three parts. The most obvious part was a hollow, echoing quiet.',
    ),
    ShopBook(
      id: 'sb11',
      title: 'A Court of Thorns and Roses',
      author: 'Sarah J. Maas',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781635575569-L.jpg',
      price: 13.99,
      rating: 4.5,
      reviewCount: 31200,
      genre: 'Fantasy',
      description: 'When 19-year-old huntress Feyre kills a wolf in the woods, a beast-like creature arrives to demand retribution.',
      pageCount: 419,
      readingTime: '6h 59m',
      tags: ['Fantasy', 'Romance', 'Young Adult'],
      isTrending: true,
      sampleText: 'The forest had become a labyrinth of snow and ice. I\'d been tracking the doe for an hour, and my fingers were so numb I could barely hold my bow.',
    ),
    ShopBook(
      id: 'sb12',
      title: 'Piranesi',
      author: 'Susanna Clarke',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781635575996-L.jpg',
      price: 12.99,
      discountPrice: 7.99,
      rating: 4.2,
      reviewCount: 7800,
      genre: 'Fantasy',
      description: 'Piranesi lives in the House. Perhaps he always has. In his notebooks, he explores its winding halls, discovering the secrets it hides.',
      pageCount: 272,
      readingTime: '4h 32m',
      tags: ['Fantasy', 'New Releases'],
      isNew: true,
      sampleText: 'When the Moon rose in the Third Northern Hall I went to the Ninth Vestibule to witness the Flooding. I took with me the two Bowls I keep by the Door.',
    ),

    // ── Classics ──────────────────────────────────────────
    ShopBook(
      id: 'sb13',
      title: 'Pride and Prejudice',
      author: 'Jane Austen',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780141439518-L.jpg',
      price: 7.99,
      rating: 4.7,
      reviewCount: 45000,
      genre: 'Classics',
      description: 'Since its publication in 1813, Pride and Prejudice has remained one of the most popular novels in the English language.',
      pageCount: 279,
      readingTime: '4h 39m',
      tags: ['Classics', 'Romance'],
      sampleText: 'It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.',
    ),
    ShopBook(
      id: 'sb14',
      title: 'To Kill a Mockingbird',
      author: 'Harper Lee',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780060935467-L.jpg',
      price: 8.99,
      rating: 4.8,
      reviewCount: 52000,
      genre: 'Classics',
      description: 'The unforgettable novel of a childhood in a sleepy Southern town and the crisis of conscience that rocked it.',
      pageCount: 281,
      readingTime: '4h 41m',
      tags: ['Classics', 'Fiction'],
      sampleText: 'When he was nearly thirteen, my brother Jem got his arm badly broken at the elbow. When it healed, and Jem\'s fears of never being able to play football were assuaged, he was seldom self-conscious about his injury.',
    ),
    ShopBook(
      id: 'sb15',
      title: 'Jane Eyre',
      author: 'Charlotte Brontë',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780141441146-L.jpg',
      price: 6.99,
      discountPrice: 4.99,
      rating: 4.5,
      reviewCount: 28900,
      genre: 'Classics',
      description: 'Orphaned as a child, Jane Eyre endures a bleak existence at Lowood School before becoming governess at Thornfield Hall.',
      pageCount: 507,
      readingTime: '8h 27m',
      tags: ['Classics', 'Romance'],
      sampleText: 'There was no possibility of taking a walk that day. We had been wandering, indeed, in the leafless shrubbery an hour in the morning.',
    ),

    // ── Self-Help ─────────────────────────────────────────
    ShopBook(
      id: 'sb16',
      title: 'The Subtle Art of Not Giving a F*ck',
      author: 'Mark Manson',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780062457714-L.jpg',
      price: 13.99,
      rating: 4.3,
      reviewCount: 38400,
      genre: 'Self-Help',
      description: 'A counterintuitive approach to living a good life. Manson argues that improving our lives hinges on our ability to handle adversity.',
      pageCount: 224,
      readingTime: '3h 44m',
      tags: ['Self-Help', 'Best Sellers'],
      isBestseller: true,
      sampleText: 'The desire for more positive experience is itself a negative experience. And, paradoxically, the acceptance of one\'s negative experience is itself a positive experience.',
    ),
    ShopBook(
      id: 'sb17',
      title: 'Think Again',
      author: 'Adam Grant',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781984878106-L.jpg',
      price: 14.99,
      discountPrice: 11.99,
      rating: 4.4,
      reviewCount: 9200,
      genre: 'Self-Help',
      description: 'The bestselling author examines the critical art of rethinking: learning to question your opinions and open other people\'s minds.',
      pageCount: 307,
      readingTime: '5h 7m',
      tags: ['Self-Help', 'New Releases'],
      isNew: true,
      isTrending: true,
      sampleText: 'Part of the problem is lazy thinking. We often prefer the ease of clinging to old views over the difficulty of grappling with new ones.',
    ),
    ShopBook(
      id: 'sb18',
      title: 'The Power of Habit',
      author: 'Charles Duhigg',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780812981605-L.jpg',
      price: 11.99,
      rating: 4.4,
      reviewCount: 21800,
      genre: 'Self-Help',
      description: 'Award-winning business reporter Charles Duhigg takes us to the thrilling edge of scientific discoveries that explain why habits exist and how they can be changed.',
      pageCount: 371,
      readingTime: '6h 11m',
      tags: ['Self-Help'],
      sampleText: 'She was the scientists\' favorite participant. Lisa Allen, according to her file, was thirty-four years old, had started smoking and drinking when she was sixteen.',
    ),

    // ── Young Adult ───────────────────────────────────────
    ShopBook(
      id: 'sb19',
      title: 'The Hunger Games',
      author: 'Suzanne Collins',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780439023481-L.jpg',
      price: 10.99,
      rating: 4.7,
      reviewCount: 58000,
      genre: 'Young Adult',
      description: 'In the ruins of a place once known as North America lies the nation of Panem. Katniss Everdeen takes her sister\'s place in the deadly Hunger Games.',
      pageCount: 374,
      readingTime: '6h 14m',
      tags: ['Young Adult', 'Fiction', 'Best Sellers'],
      isBestseller: true,
      sampleText: 'When I wake up, the other side of the bed is cold. My fingers stretch out, seeking Prim\'s warmth but finding only the rough canvas cover of the mattress.',
    ),
    ShopBook(
      id: 'sb20',
      title: 'Six of Crows',
      author: 'Leigh Bardugo',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781627792127-L.jpg',
      price: 12.99,
      rating: 4.6,
      reviewCount: 14600,
      genre: 'Young Adult',
      description: 'Criminal prodigy Kaz Brekker is offered a chance at a deadly heist that could make him rich beyond his wildest dreams. But he can\'t pull it off alone.',
      pageCount: 465,
      readingTime: '7h 45m',
      tags: ['Young Adult', 'Fantasy'],
      isTrending: true,
      sampleText: 'Joost had two problems: the first was that he was a guard—and not a very good one. The second was a girl.',
    ),
    ShopBook(
      id: 'sb21',
      title: 'The Fault in Our Stars',
      author: 'John Green',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780525478812-L.jpg',
      price: 9.99,
      discountPrice: 6.99,
      rating: 4.4,
      reviewCount: 41200,
      genre: 'Young Adult',
      description: 'Despite the tumor-shrinking medical miracle, Hazel\'s story is about to be completely rewritten when a gorgeous plot twist named Augustus Waters walks into her support group.',
      pageCount: 313,
      readingTime: '5h 13m',
      tags: ['Young Adult', 'Romance'],
      sampleText: 'Late in the winter of my seventeenth year, my mother decided I was depressed, presumably because I rarely left the house.',
    ),

    // ── More Fiction / Trending ────────────────────────────
    ShopBook(
      id: 'sb22',
      title: 'Lessons in Chemistry',
      author: 'Bonnie Garmus',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780385547345-L.jpg',
      price: 14.99,
      rating: 4.5,
      reviewCount: 16800,
      genre: 'Fiction',
      description: 'Chemist Elizabeth Zott is not your average woman. Her all-male team at Hastings Research Institute take her science less than seriously.',
      pageCount: 390,
      readingTime: '6h 30m',
      tags: ['Fiction', 'New Releases'],
      isNew: true,
      isTrending: true,
      sampleText: 'Back in 1961, when women wore shirtwaist dresses and joined garden clubs and set their husbands\' dinners on the table precisely at six thirty, Elizabeth Zott was somewhere else entirely.',
    ),
    ShopBook(
      id: 'sb23',
      title: 'The House in the Cerulean Sea',
      author: 'TJ Klune',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9781250217288-L.jpg',
      price: 13.99,
      discountPrice: 9.99,
      rating: 4.7,
      reviewCount: 13500,
      genre: 'Fantasy',
      description: 'A magical island. A dangerous task. A discovery that will change the world. Linus Baker leads a quiet life, until the day he receives an assignment.',
      pageCount: 396,
      readingTime: '6h 36m',
      tags: ['Fantasy', 'Fiction'],
      isTrending: true,
      sampleText: 'Linus Baker was a by-the-book caseworker at the Department in Charge of Magical Youth. He was not in the habit of disobeying rules.',
    ),
    ShopBook(
      id: 'sb24',
      title: 'Educated',
      author: 'Tara Westover',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780399590504-L.jpg',
      price: 12.99,
      rating: 4.7,
      reviewCount: 34800,
      genre: 'Self-Help',
      description: 'Born to survivalists in the mountains of Idaho, Tara Westover was kept out of school. Her quest for knowledge transformed her.',
      pageCount: 334,
      readingTime: '5h 34m',
      tags: ['Self-Help', 'Best Sellers'],
      isBestseller: true,
      sampleText: 'I\'m standing on the red railway car that my father has settled on the mountain. The valley is dry; the sun-scorched earth is beginning to crack.',
    ),
    ShopBook(
      id: 'sb25',
      title: 'Circe',
      author: 'Madeline Miller',
      coverImage: 'https://covers.openlibrary.org/b/isbn/9780316556347-L.jpg',
      price: 11.99,
      rating: 4.6,
      reviewCount: 19700,
      genre: 'Fantasy',
      description: 'In the house of Helios, god of the sun, a daughter is born. Circe is a strange child—not powerful like her father, nor viciously alluring like her mother.',
      pageCount: 385,
      readingTime: '6h 25m',
      tags: ['Fantasy', 'Classics', 'Fiction'],
      isBestseller: true,
      sampleText: 'When I was born, the name for what I was did not exist. They called me nymph, assuming I would be like my mother and all the other nymphs.',
    ),
  ];

  // ── Shelf helpers ─────────────────────────────────────────
  static List<ShopBook> getFeatured() =>
      allBooks.where((b) => b.isTrending && b.isBestseller).toList()
        ..addAll(allBooks.where((b) => b.isTrending && !b.isBestseller).take(1));

  static ShopBook get featuredBook => allBooks.firstWhere(
        (b) => b.isTrending && b.isBestseller,
        orElse: () => allBooks.first,
      );

  static List<ShopBook> getTrending() =>
      allBooks.where((b) => b.isTrending).toList();

  static List<ShopBook> getBestsellers() =>
      allBooks.where((b) => b.isBestseller).toList();

  static List<ShopBook> getNewReleases() =>
      allBooks.where((b) => b.isNew).toList();

  static List<ShopBook> getRecommended() {
    // Mix: high-rated books not in trending/bestsellers
    final recs = allBooks.where((b) => !b.isTrending && !b.isBestseller).toList();
    recs.sort((a, b) => b.rating.compareTo(a.rating));
    return recs.take(8).toList();
  }

  static List<ShopBook> getClassics() =>
      allBooks.where((b) => b.genre == 'Classics' || b.tags.contains('Classics')).toList();

  static List<ShopBook> getShortReads() {
    final shorts = List<ShopBook>.from(allBooks);
    shorts.sort((a, b) => a.pageCount.compareTo(b.pageCount));
    return shorts.take(8).toList();
  }

  static List<ShopBook> getByCategory(BookCategory category) {
    if (category == BookCategory.all) return allBooks;
    if (category == BookCategory.bestSellers) return getBestsellers();
    if (category == BookCategory.newReleases) return getNewReleases();
    return allBooks.where((b) =>
        b.genre == category.label || b.tags.contains(category.label)).toList();
  }

  static List<ShopBook> searchBooks(String query) {
    final q = query.toLowerCase();
    return allBooks.where((b) =>
        b.title.toLowerCase().contains(q) ||
        b.author.toLowerCase().contains(q) ||
        b.genre.toLowerCase().contains(q)).toList();
  }

  static List<ShopBook> sortBooks(List<ShopBook> books, BookSortOption sort) {
    final sorted = List<ShopBook>.from(books);
    switch (sort) {
      case BookSortOption.popular:
        sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
      case BookSortOption.newest:
        sorted.sort((a, b) {
          final aScore = (a.isNew ? 2 : 0) + (a.isTrending ? 1 : 0);
          final bScore = (b.isNew ? 2 : 0) + (b.isTrending ? 1 : 0);
          return bScore.compareTo(aScore);
        });
        break;
      case BookSortOption.highestRated:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case BookSortOption.priceLowHigh:
        sorted.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case BookSortOption.priceHighLow:
        sorted.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
    }
    return sorted;
  }
}
