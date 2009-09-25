require 'brewkit'

class Couchdb <Formula
  @url='http://apache.multihomed.net/couchdb/0.9.1/apache-couchdb-0.9.1.tar.gz'
  @homepage='http://couchdb.apache.org/'
  @md5='9583efae5adfb3f9043e970fef825561'

  depends_on 'spidermonkey'
  depends_on 'icu4c'
  depends_on 'erlang'

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make"
    system "make install"
    system "mkdir", "-p", prefix + 'var' + 'log' + 'couchdb'
    system "touch", prefix + 'var' + 'log' + 'couchdb' + '.gitignore'
    system "mkdir", "-p", prefix + 'var' + 'lib' + 'couchdb'
    system "touch", prefix + 'var' + 'lib' + 'couchdb' + '.gitignore'
  end
end
