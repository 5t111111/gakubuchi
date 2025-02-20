module Gakubuchi
  class Template
    extend ::Forwardable

    attr_reader :source_path, :extname
    def_delegators :source_path, :basename, :hash

    %w(== === eql?).each do |method_name|
      define_method(method_name) do |other|
        self.class == other.class && source_path.public_send(method_name, other.source_path)
      end
    end

    def self.all
      ::Dir.glob(root.join('**/*.html*')).map { |source_path| new(source_path) }
    end

    def self.root
      ::Rails.root.join('app/assets', ::Gakubuchi.configuration.template_directory)
    end

    def initialize(source_path)
      path = ::Pathname.new(source_path)
      root = self.class.root

      @extname = extract_extname(path)
      @source_path = path.absolute? ? path : root.join(path)

      case
      when !@extname.include?('html')
        fail Error::InvalidTemplate, 'source path must refer to a template file'
      when !@source_path.fnmatch?(root.join('*').to_s)
        fail Error::InvalidTemplate, "template must exist in #{root}"
      end
    end

    def destination_path
      ::Rails.public_path.join(logical_path)
    end

    def digest_path
      resolved_path = view_context.asset_digest_path(logical_path.to_s)
      return if resolved_path.nil?

      ::Pathname.new(::File.join(::Rails.public_path, view_context.assets_prefix, resolved_path))
    end

    def logical_path
      dirname = source_path.relative_path_from(self.class.root).dirname
      ::Pathname.new(dirname).join("#{basename(extname)}.html")
    end

    private

    def extract_extname(path)
      extname = path.extname
      extname.empty? ? extname : "#{extract_extname(path.basename(extname))}#{extname}"
    end

    def view_context
      @view_context ||= ::ActionView::Base.new
    end
  end
end
