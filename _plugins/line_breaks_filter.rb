module Jekyll
  module LineBreaksFilter
    def line_breaks(input)
      input.gsub(/\n\n/, '<br><br>')
    end
  end
end

Liquid::Template.register_filter(Jekyll::LineBreaksFilter)

