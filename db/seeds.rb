# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


denis = Teacher.create(name: 'Denis Vogel')
malte = Teacher.create(name: 'Malte Witte')

algebra2 = Course.create(title: 'Algebra 2')
la2 = Course.create(title: 'Lineare Algebra 2')

a2ss16 = Lecture.create(term: 'SS 2016', course: algebra2, teacher: denis)
a2ss17 = Lecture.create(term: 'SS 2017', course: algebra2, teacher: malte)
la2ss17 = Lecture.create(term: 'SS 2017', course: la2, teacher: denis)

la2e01 = Lesson.create(lecture: la2ss17, number: 1, date: Date.today)

tensor_product = Tag.create(title: 'Tensorprodukt von Moduln')
jordan_normal_form = Tag.create(title: 'Jordansche Normalform')
abelian_categories = Tag.create(title: 'Abelsche Kategorien')

la2.course_contents.create(tag: tensor_product)
la2.course_contents.create(tag: jordan_normal_form)
algebra2.course_contents.create(tag: tensor_product)
algebra2.course_contents.create(tag: abelian_categories)
a2ss17.disabled_contents.create(tag: tensor_product)

la2e01.lesson_contents.create(tag: jordan_normal_form)

medium = Medium.create(title: 'LineareAlgebra.S02E15', author: 'Denis Vogel',
has_video_stream?: true, has_video_file?: true, has_video_thumbnail?: true,
has_manuscript?: true, has_external_reference?: false,
video_file_link: 'https://mampf.mathi.uni-heidelberg.de/ss17/Lineare_Algebra_2/LineareAlgebra.S02E15.1080p/LineareAlgebra.S02E15.1080p.mp4',
video_stream_link:'https://mampf.mathi.uni-heidelberg.de/ss17/Lineare_Algebra_2/LineareAlgebra.S02E15.1080p/LineareAlgebra.S02E15.1080p.html',
manuscript_link: 'https://mampf.mathi.uni-heidelberg.de/ss17/Lineare_Algebra_2/pdf/LineareAlgebra.S02E15.pdf',
width: 1620, height: 1080, length: 5388,
embedded_width: 1280, embedded_height: 720,
pages: 4)
