
require 'won/version'

module Won
  
  module Simple
    
    CALLERS_TO_IGNORE = [ # :nodoc:
                         /lib\/won.*\.rb$/, # all won code
                         /\(.*\)/, # generated code
                         /rubygems\/custom_require\.rb$/, # rubygems require hacks
                         /active_support/, # active_support require hacks
                         /bundler(\/runtime)?\.rb/, # bundler require hacks
                         /<internal:/ # internal in ruby >= 1.9.2
                        ]

    CALLERS_TO_IGNORE.concat(RUBY_IGNORE_CALLERS) if defined?(RUBY_IGNORE_CALLERS)

    def caller_files
      caller_locations.map { |file,line| file }
    end

    def caller_locations
      caller(1).
        map { |line| line.split(/:(?=\d|in )/)[0,2] }.
        reject { |file,line| CALLERS_TO_IGNORE.any? { |pattern| file =~ pattern } }
    end

    def inline(file=nil)
      file = (file.nil? || file == true) ? (File.expand_path($0)) : file
      
      begin
        io = ::IO.respond_to?(:binread) ? ::IO.binread(file) : ::IO.read(file)
        app, data = io.gsub("\r\n", "\n").split(/^__END__$/, 2)
        unless data
          data,app = app,data
        end
      rescue Errno::ENOENT
        raise "Template not found: #{file}"
      end

      lines = app ? app.count("\n") + 1 : 1
      template = nil

      @templates ||= {}
      @views ||= './won'

      data.each_line do |line|
        lines += 1
        if line =~ /^@@\s*(.*\S)\s*$/
          template = ''
          @templates[$1.to_sym] = [template, file, lines]
        elsif template
          template << line
        end
      end
    end

    def str data, scope = nil
      case data
      when Symbol
        body, path, line = @templates[data]
        if body
          body = body.call if body.respond_to?(:call)
        else
          path = ::File.join( @views, "#{data}.str")
          begin
            body = IO.read( path )
            @templates[data] = [body,path,1]
          rescue
            raise "Template file missing #{path}" 
          end
        end
      when Proc,String
        body = data.is_a?(String) ? data : data.call
        path, line = self.class.caller_locations.first
      else
        class_name = data.class.to_s
        candidate = data[:view] if !candidate && data.respond_to?(:has_key?) && data.has_key?(:view)
        candidate = [class_name.to_sym, class_name.downcase.to_sym].detect  { |x| @templates.has_key?(x) } unless candidate
        raise ArgumentError unless @templates.has_key?(candidate)
        scope = data
        body, path, line = @templates[candidate]
      end

      line = line.to_i
      compiled = "%Q{#{body}}"
      unless scope
        out = TOPLEVEL_BINDING.eval compiled, path, line
      else
        case scope
        when Binding
          out = scope.eval(compiled , path, line )
        else
          scope.extend Hook
          out = scope.instance_eval(compiled, path, line)
        end
      end # unless
      out.chomp
    end # str

    def template name
      if block_given?
        path, line = self.class.caller_locations.first
        @templates[name.to_sym] = yield, path, line
      end
    end

  end # Simple
  
  module Hook
    def method_missing(method, *args, &block)
      if self.respond_to?(:has_key?) && self.has_key?(method)
        self[method]
      else
        path, line = self.class.caller_locations.first
        raise "#{path}:#{line} in '#{method}' not found"
      end
    end
  end
  
end



