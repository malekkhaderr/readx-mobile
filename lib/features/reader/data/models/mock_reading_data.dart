class MockChapter {
  final String bookTitle;
  final String chapterTitle;
  final int chapterNumber;
  final int totalChapters;
  final double progress;
  final List<ReadingBlock> blocks;

  const MockChapter({
    required this.bookTitle,
    required this.chapterTitle,
    required this.chapterNumber,
    required this.totalChapters,
    required this.progress,
    required this.blocks,
  });
}

enum BlockType { paragraph, quote, heading }

class ReadingBlock {
  final BlockType type;
  final String text;
  final bool hasDropCap;

  const ReadingBlock({
    required this.type,
    required this.text,
    this.hasDropCap = false,
  });
}

class MockReadingData {
  static const chapter = MockChapter(
    bookTitle: 'The Echoes of Time',
    chapterTitle: 'Chapter 12: The Whispering Gallery',
    chapterNumber: 12,
    totalChapters: 24,
    progress: 0.48,
    blocks: [
      ReadingBlock(
        type: BlockType.paragraph,
        hasDropCap: true,
        text:
            'he air in the gallery was thick with the scent of old parchment and beeswax. Lyra stepped softly, her eyes tracing the intricate patterns of gold leaf that adorned the vaulted ceiling. Every footstep echoed like a whispered memory against the polished marble floor.',
      ),
      ReadingBlock(
        type: BlockType.quote,
        text:
            '"In the silence of the archive, the truth finds its voice." The Master had told her. Now, standing before the Great Seal, she finally understood what he meant.',
      ),
      ReadingBlock(
        type: BlockType.paragraph,
        text:
            'She reached out a trembling hand, her fingers hovering just inches from the ancient stonework. It pulsed with a faint, rhythmic warmth, a heartbeat of magic that had survived centuries of neglect. Outside, the storm raged, but here, within the heart of the Citadel, there was only the steady hum of history waiting to be rediscovered.',
      ),
      ReadingBlock(
        type: BlockType.paragraph,
        text:
            'With a soft click that resonated through her very bones, the seal began to rotate. Light, pure and silver as moonlight, bled from the seams, illuminating the dusty corners of the room. Lyra held her breath. The game was no longer a game; the story was writing itself through her very actions.',
      ),
    ],
  );

  static const int dayStreak = 12;
}
