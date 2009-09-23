require 'brewkit'

class Libxml2 <Formula
  @url='http://xmlsoft.org/sources/libxml2-2.7.4.tar.gz'
  @homepage='http://xmlsoft.org/'
  @md5='961cce07211049e3bb20c5b98a1281b4'

  def install
    system './configure', "--prefix=#{prefix}"
    system 'make install'
  end
end