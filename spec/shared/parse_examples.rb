# frozen_string_literal: true

shared_examples 'parse fixture_examples' do |parser|
  yml_examples.each do |example|
    it "parses '#{example['source']}'" do
      (parser || described_class).parse(example['source']).tap do |email|
        expect(email.local).to eq(example['local'])
        expect(email.domain).to eq(example['domain'])
        expect(email.name).to eq(example['name'])
        expect(email.tag).to eq(example['tag']) if example.key?('tag')
        expect(email.username).to eq(example['username']) if example.key?('username')
        expect(email.address).to eq("#{example['local']}@#{example['domain']}")
      end
    end
  end
end
