module BlogpostsHelper
  def markdown(text)
    options = [:filter_html, :no_intraemphasis, :fenced_code, :gh_blockcode]
    Redcarpet.new(text, *options).to_html.html_safe
  end
end
