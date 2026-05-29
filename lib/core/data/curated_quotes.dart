class CuratedQuote {
  final String text;
  final String author;
  final String book;

  const CuratedQuote({required this.text, required this.author, required this.book});

  bool get isArabic => text.contains(RegExp(r'[؀-ۿ]'));
}

const List<CuratedQuote> curatedQuotes = [
  // ── English Literature ────────────────────────────────
  CuratedQuote(text: 'A reader lives a thousand lives before he dies. The man who never reads lives only one.', author: 'George R.R. Martin', book: 'A Dance with Dragons'),
  CuratedQuote(text: 'So we beat on, boats against the current, borne back ceaselessly into the past.', author: 'F. Scott Fitzgerald', book: 'The Great Gatsby'),
  CuratedQuote(text: 'It is only with the heart that one can see rightly; what is essential is invisible to the eye.', author: 'Antoine de Saint-Exupéry', book: 'The Little Prince'),
  CuratedQuote(text: 'Not all those who wander are lost.', author: 'J.R.R. Tolkien', book: 'The Lord of the Rings'),
  CuratedQuote(text: 'It does not do to dwell on dreams and forget to live.', author: 'J.K. Rowling', book: 'Harry Potter and the Philosopher\'s Stone'),
  CuratedQuote(text: 'The only way out of the labyrinth of suffering is to forgive.', author: 'John Green', book: 'Looking for Alaska'),
  CuratedQuote(text: 'Whatever you do, do it with all your might.', author: 'Marcus Tullius Cicero', book: 'De Officiis'),
  CuratedQuote(text: 'We accept the love we think we deserve.', author: 'Stephen Chbosky', book: 'The Perks of Being a Wallflower'),
  CuratedQuote(text: 'Until I feared I would lose it, I never loved to read. One does not love breathing.', author: 'Harper Lee', book: 'To Kill a Mockingbird'),
  CuratedQuote(text: 'The world breaks everyone, and afterward, some are strong at the broken places.', author: 'Ernest Hemingway', book: 'A Farewell to Arms'),
  CuratedQuote(text: 'Who controls the past controls the future. Who controls the present controls the past.', author: 'George Orwell', book: '1984'),
  CuratedQuote(text: 'There is no greater agony than bearing an untold story inside you.', author: 'Maya Angelou', book: 'I Know Why the Caged Bird Sings'),
  CuratedQuote(text: 'Happiness can be found even in the darkest of times, if one only remembers to turn on the light.', author: 'J.K. Rowling', book: 'Harry Potter and the Prisoner of Azkaban'),
  CuratedQuote(text: 'The marks humans leave are too often scars.', author: 'John Green', book: 'The Fault in Our Stars'),
  CuratedQuote(text: 'In the middle of difficulty lies opportunity.', author: 'Albert Einstein', book: 'Letters'),

  // ── Arabic & Islamic Wisdom ───────────────────────────
  CuratedQuote(text: 'اطلبوا العلم من المهد إلى اللحد', author: 'النبي محمد ﷺ', book: 'حديث شريف'),
  CuratedQuote(text: 'من جدّ وجد، ومن زرع حصد', author: 'مثل عربي', book: 'الحكمة العربية'),
  CuratedQuote(text: 'العقل السليم في الجسم السليم', author: 'مثل عربي', book: 'الحكمة العربية'),
  CuratedQuote(text: 'الكتب خير جليس في الأنام', author: 'المتنبي', book: 'ديوان المتنبي'),
  CuratedQuote(text: 'إذا هبّت رياحك فاغتنمها', author: 'علي بن أبي طالب', book: 'نهج البلاغة'),
  CuratedQuote(text: 'العلم نور والجهل ظلام', author: 'مثل عربي', book: 'الحكمة العربية'),
  CuratedQuote(text: 'الصبر مفتاح الفرج', author: 'مثل عربي', book: 'الحكمة العربية'),
  CuratedQuote(text: 'لا تؤجّل عمل اليوم إلى الغد', author: 'مثل عربي', book: 'الحكمة العربية'),
  CuratedQuote(text: 'أعلمه الرماية كل يوم فلما اشتد ساعده رماني', author: 'معن بن أوس', book: 'الشعر العربي'),
  CuratedQuote(text: 'ليس الجمال بأثواب تزيّننا إنّ الجمال جمال العلم والأدب', author: 'علي بن أبي طالب', book: 'نهج البلاغة'),

  // ── Philosophy & Thought ──────────────────────────────
  CuratedQuote(text: 'The unexamined life is not worth living.', author: 'Socrates', book: 'Apology'),
  CuratedQuote(text: 'He who has a why to live can bear almost any how.', author: 'Friedrich Nietzsche', book: 'Twilight of the Idols'),
  CuratedQuote(text: 'The only true wisdom is in knowing you know nothing.', author: 'Socrates', book: 'Dialogues'),
  CuratedQuote(text: 'Man is condemned to be free; because once thrown into the world, he is responsible for everything he does.', author: 'Jean-Paul Sartre', book: 'Being and Nothingness'),
  CuratedQuote(text: 'To live is the rarest thing in the world. Most people exist, that is all.', author: 'Oscar Wilde', book: 'The Soul of Man Under Socialism'),

  // ── Modern & Self-Help ────────────────────────────────
  CuratedQuote(text: 'You do not rise to the level of your goals. You fall to the level of your systems.', author: 'James Clear', book: 'Atomic Habits'),
  CuratedQuote(text: 'The obstacle is the way.', author: 'Ryan Holiday', book: 'The Obstacle Is the Way'),
  CuratedQuote(text: 'Your time is limited, don\'t waste it living someone else\'s life.', author: 'Steve Jobs', book: 'Stanford Commencement Speech'),
  CuratedQuote(text: 'Start where you are. Use what you have. Do what you can.', author: 'Arthur Ashe', book: 'Days of Grace'),
  CuratedQuote(text: 'The best time to plant a tree was 20 years ago. The second best time is now.', author: 'Chinese Proverb', book: 'Traditional Wisdom'),
  CuratedQuote(text: 'What you get by achieving your goals is not as important as what you become by achieving your goals.', author: 'Zig Ziglar', book: 'See You at the Top'),

  // ── Science Fiction & Fantasy ─────────────────────────
  CuratedQuote(text: 'Fear is the mind-killer. Fear is the little-death that brings total obliteration.', author: 'Frank Herbert', book: 'Dune'),
  CuratedQuote(text: 'The story so far: In the beginning the Universe was created. This has made a lot of people very angry and been widely regarded as a bad move.', author: 'Douglas Adams', book: 'The Restaurant at the End of the Universe'),
  CuratedQuote(text: 'Do or do not. There is no try.', author: 'Yoda', book: 'Star Wars: The Empire Strikes Back'),
  CuratedQuote(text: 'It matters not what someone is born, but what they grow to be.', author: 'J.K. Rowling', book: 'Harry Potter and the Goblet of Fire'),

  // ── Eastern Wisdom ────────────────────────────────────
  CuratedQuote(text: 'The journey of a thousand miles begins with a single step.', author: 'Lao Tzu', book: 'Tao Te Ching'),
  CuratedQuote(text: 'Knowing others is intelligence; knowing yourself is true wisdom.', author: 'Lao Tzu', book: 'Tao Te Ching'),
  CuratedQuote(text: 'Yesterday I was clever, so I wanted to change the world. Today I am wise, so I am changing myself.', author: 'Rumi', book: 'Masnavi'),
  CuratedQuote(text: 'The wound is the place where the light enters you.', author: 'Rumi', book: 'Collected Poems'),
  CuratedQuote(text: 'Do not be satisfied with the stories that come before you. Unfold your own myth.', author: 'Rumi', book: 'Masnavi'),
  CuratedQuote(text: 'When you let go of what you are, you become what you might be.', author: 'Lao Tzu', book: 'Tao Te Ching'),

  // ── African Proverbs ──────────────────────────────────
  CuratedQuote(text: 'If you want to go fast, go alone. If you want to go far, go together.', author: 'African Proverb', book: 'Traditional Wisdom'),
  CuratedQuote(text: 'A child who is not embraced by the village will burn it down to feel its warmth.', author: 'African Proverb', book: 'Traditional Wisdom'),
  CuratedQuote(text: 'However long the night, the dawn will break.', author: 'African Proverb', book: 'Traditional Wisdom'),
];
