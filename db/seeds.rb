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

tensor_product = Tag.create(title: 'Tensorprodukt von Moduln')
jordan_normal_form = Tag.create(title: 'Jordansche Normalform')
abelian_categories = Tag.create(title: 'Abelsche Kategorien')

la2.contents.create(tag: tensor_product)
la2.contents.create(tag: jordan_normal_form)
algebra2.contents.create(tag: tensor_product)
algebra2.contents.create(tag: abelian_categories)
a2ss17.disabled_contents.create(tag: tensor_product)

video = VideoFile.create(title: 'LineareAlgebra.S02E15', author: 'Denis Vogel',
link:'https://mampf.mathi.uni-heidelberg.de/ss17/Lineare_Algebra_2/LineareAlgebra.S02E15.1080p/LineareAlgebra.S02E15.1080p.mp4',
width: 1620, height: 1080, length: 5388, frames_per_second: 20, codec: 'h264')

stream = VideoStream.create(title:'LineareAlgebra.S02E15',author:'Denis Vogel',
link:'https://mampf.mathi.uni-heidelberg.de/ss17/Lineare_Algebra_2/LineareAlgebra.S02E15.1080p/LineareAlgebra.S02E15.1080p.html',
width: 1280, height: 720,length: 5388, frames_per_second: 20, authoring_software: 'Camtasia 9.0')

pdf = Manuscript.create(title:'LineareAlgebra.S02E15',author:'Denis Vogel',link:'https://mampf.mathi.uni-heidelberg.de/ss17/Lineare_Algebra_2/pdf/LineareAlgebra.S02E15.pdf',
pages: 4)

asset = LearningAsset.create(title: 'LineareAlgebra.S01E15', description: 'KaViaR LA2E15', project: 'kaviar', media: [video, stream, pdf])
