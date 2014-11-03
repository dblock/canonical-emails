shared_examples 'transform fixture_examples' do
  yml_examples.each do |example|
    it "transforms '#{example['source']}'" do
      subject.transform(example['source']).tap do |email|
        expect(email.local).to eq(example['local'])
        expect(email.domain).to eq(example['domain'])
        expect(email.name).to eq(example['name'])
      end
    end
  end
end
