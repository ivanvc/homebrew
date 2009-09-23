require 'brewkit'

class Libxslt <Formula
  @url='http://xmlsoft.org/sources/libxslt-1.1.25.tar.gz'
  @homepage='http://xmlsoft.org/xslt/'
  @md5='50c5ba1218262ac10669961b32db405a'

  depends_on 'libxml2'

  def install
    system  './configure', 
            "--prefix=#{prefix}", 
            "--with-libxml-prefix=#{HOMEBREW_PREFIX}",
            "--with-libxml-include-prefix=#{HOMEBREW_PREFIX}/include"
            "--with-libxml-libs-prefix=#{HOMEBREW_PREFIX}/lib"
    system "make install"
  end
end
