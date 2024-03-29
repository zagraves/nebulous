module Nebulous
  class DelimiterDetector
    LINE_DELIMITERS = [
      [/CRLF/, "\n"],
      [/CR, LF/, "\r"],
      [/CR(?!,)/, "\r"]
    ]

    COLUMN_DELIMITERS = [',', ';', "\t", '|']

    attr_reader :path

    def initialize(path, *args)
      @path = path
      @options = args.extract_options!

      raise ArgumentError unless File.exist?(@path)
    end

    def detect
      { col_sep: detect_column_delimiter,
        row_sep: detect_line_delimiter }
    end

    def detect_column_delimiter
      ln = readline

      column_delimiters.each_with_index do |exp, index|
        counts[index] = ln.split(exp).length - 1
      end

      count = counts.each_with_index.max[1]
      column_delimiters[count]
    end

    def detect_line_delimiter
      res = Terrapin::CommandLine.new('file', ':path').run(path: path).chomp

      map = line_delimiters.map do |sep|
        sep[1] if res =~ sep[0]
      end.compact

      map.first || line_delimiters[0][1]
    end

    private

    def line_delimiters
      @options.fetch(:line_delimiters, LINE_DELIMITERS)
    end

    def column_delimiters
      @options.fetch(:column_delimiters, COLUMN_DELIMITERS)
    end

    def encoding
      @options.fetch(:encoding, Encoding::UTF_8.to_s)
    end

    def counts
      @counts ||= column_delimiters.map { 0 }
    end

    def readline
      ln = ''

      File.open(path, 'r') do |io|
        while ln.chomp.empty?
          ln += io.readline
        end
      end

      ln.encode(encoding, invalid: :replace)
    end
  end
end
