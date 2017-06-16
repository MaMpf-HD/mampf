# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

denis = Teacher.create(name: 'Denis Vogel')
malte = Teacher.create(name: 'Malte Witte')

ss16 = SummerTerm.create(year: 2016)
ss17 = SummerTerm.create(year: 2017)

tensor_product = Tag.create(title: 'Tensorprodukt von Moduln')
jordan_normal_form = Tag.create(title: 'Jordansche Normalform')
abelian_categories = Tag.create(title: 'Abelsche Kategorien')
jordan_normal_form.related_tags = [tensor_product, abelian_categories]

algebra2 = Course.create do |c|
  c.title = 'Algebra 2'
  c.tags = [tensor_product, abelian_categories]
end

lineare_algebra2 = Course.create do |c|
  c.title = 'Lineare Algebra 2'
  c.tags = [tensor_product, jordan_normal_form]
end

a2_ss16 = Lecture.create do |l|
  l.term = ss16
  l.course = algebra2
  l.teacher = denis
end

a2_ss17 = Lecture.create do |l|
  l.term = ss17
  l.course = algebra2
  l.teacher = malte
  l.disabled_tags = [tensor_product]
end

la2_ss17 = Lecture.create do |l|
  l.term = ss17
  l.course = lineare_algebra2
  l.teacher = denis
end

la2_ss17_e01 = Lesson.create do |l|
  l.lecture = la2_ss17
  l.number = 1
  l.date = '2017-06-10'
  l.tags = [jordan_normal_form]
end

la2_ss17_e01_recording = Medium.create do |m|
  m.title = 'LineareAlgebra.S02E15'
  m.author = 'Denis Vogel'
  m.video_file_link = 'https://mampf.mathi.uni-heidelberg.de/ss17/' \
                      'Lineare_Algebra_2/' + 'LineareAlgebra.S02E15.1080p/' \
                      'LineareAlgebra.S02E15.1080p.mp4'
  m.video_stream_link = 'https://mampf.mathi.uni-heidelberg.de/ss17/' \
                        'Lineare_Algebra_2/LineareAlgebra.S02E15.1080p/' \
                        'LineareAlgebra.S02E15.1080p.html'
  m.manuscript_link = 'https://mampf.mathi.uni-heidelberg.de/ss17/' \
                      'Lineare_Algebra_2/pdf/LineareAlgebra.S02E15.pdf'
  m.width = 1620
  m.height = 1080
  m.length = 5388
  m.embedded_width = 1280
  m.embedded_height = 720
  m.pages = 4
end

la2_ss17_e01_kaviar = KaviarAsset.create do |l|
  l.description = 'KaviarLA2'
  l.course = lineare_algebra2
  l.lecture = la2_ss17
  l.lesson =  la2_ss17_e01
  l.media = [la2_ss17_e01_recording]
  l.tags = [jordan_normal_form]
end
